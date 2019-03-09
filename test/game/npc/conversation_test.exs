defmodule Game.NPC.ConversationTest do
  use Data.ModelCase

  alias Data.Script.Line
  alias Game.Channel
  alias Game.Character
  alias Game.Message
  alias Game.NPC.Conversation
  alias Game.NPC.State
  alias Game.Quest

  describe "starting a new conversation" do
    setup do
      user = create_user()
      character = Character.to_simple(create_character(user))

      npc = create_npc(%{
        name: "Store Owner",
        script: [
          %Line{
            key: "start",
            message: "hello",
            listeners: [
              %{phrase: "next", key: "next"},
            ],
          },
          %Line{
            key: "next",
            message: "hello",
          },
        ],
      })

      Channel.join_tell(character)

      npc = %{npc | original_id: npc.id}
      %{character: character, npc: npc, state: %State{npc: npc}}
    end

    test "records the character and when they started", %{character: character, state: state} do
      state = Conversation.greet(state, character)

      assert %{key: "start", started_at: _} = Map.get(state.conversations, character.id)
      assert_receive {:channel, {:tell, _, %Message{message: "hello"}}}
    end
  end

  describe "continuing a conversation" do
    setup do
      user = create_user()
      character = Character.to_simple(create_character(user))

      npc = create_npc(%{
        script: [
          %Line{
            key: "start",
            message: "hello",
            unknown: "unknown",
            listeners: [
              %{phrase: "bandit", key: "bandits"},
              %{phrase: "done", key: "done"},
            ],
          },
          %Line{
            key: "bandits",
            message: "there are bandits near by",
            listeners: [
              %{phrase: "done", key: "done"},
            ],
          },
          %Line{
            key: "done",
            message: "conversation is over",
          },
        ],
      })

      Channel.join_tell(character)

      state = %State{
        npc: npc,
        conversations: %{character.id => %{key: "start", script: npc.script}}
      }

      %{character: character, npc: npc, state: state}
    end

    test "receiving a message that matches the phrase", %{character: character, state: state} do
      state = Conversation.recv(state, character, "bandit")

      assert %{key: "bandits"} = Map.get(state.conversations, character.id)
      assert_receive {:channel, {:tell, _, %Message{message: "there are bandits near by"}}}
    end

    test "receiving a message that does not match the phrase", %{character: character, state: state} do
      state = Conversation.recv(state, character, "anything else")

      assert %{key: "start"} = Map.get(state.conversations, character.id)
      assert_receive {:channel, {:tell, _, %Message{message: "unknown"}}}
    end

    test "the unknown response is null - send nothing", %{character: character, state: state} do
      state = Conversation.recv(state, character, "bandit")
      state = Conversation.recv(state, character, "unknown")

      assert %{key: "bandits"} = Map.get(state.conversations, character.id)
      refute_receive {:channel, {:tell, _, %Message{message: nil}}}, 50
    end

    test "no previous conversation is considered a greeting", %{character: character, state: state} do
      state = %{state | conversations: %{}}

      state = Conversation.recv(state, character, "first time")

      assert %{key: "start"} = Map.get(state.conversations, character.id)
      assert_receive {:channel, {:tell, _, %Message{message: "hello"}}}
    end

    test "'finishing' a conversation clears out their key", %{character: character, state: state} do
      state = Conversation.recv(state, character, "done")

      refute Map.has_key?(state.conversations, character.id)
      assert_receive {:channel, {:tell, _, %Message{message: "conversation is over"}}}
    end
  end

  describe "quest giving npcs" do
    setup do
      user = create_user()
      character = Character.to_simple(create_character(user))
      npc = create_npc(%{
        name: "Store Owner",
        is_quest_giver: true,
        script: [%Line{key: "start", message: "hello"}],
      })

      quest = create_quest(npc, %{
        script: [
          %Line{
            key: "start",
            message: "a quest opener",
            listeners: [
              %{phrase: "bandit", key: "bandits"},
            ],
          },
          %Line{
            key: "bandits",
            message: "there are bandits near by",
            trigger: "quest",
          },
        ],
      })

      Channel.join_tell(character)

      state = %State{
        npc: %{npc | original_id: npc.id},
        conversations: %{character.id => %{key: "start", script: quest.script, quest_id: quest.id}},
      }

      %{character: character, npc: npc, state: state, quest: quest}
    end

    test "starting a new conversation and the npc is a quest giver with a new quest", %{character: character, state: state} do
      state = %{state | conversations: %{}}

      state = Conversation.greet(state, character)

      assert %{key: "start", started_at: _} = Map.get(state.conversations, character.id)
      assert_receive {:channel, {:tell, _, %Message{message: "a quest opener"}}}
    end

    test "gives the quest out when the conversation dictates it", %{character: character, state: state, quest: quest} do
      state = Conversation.recv(state, character, "bandit")

      assert is_nil(Map.get(state.conversations, character.id))
      assert_receive {:channel, {:tell, _, %Message{message: "there are bandits near by"}}}

      assert Quest.progress_for(character, quest.id)
    end
  end
end
