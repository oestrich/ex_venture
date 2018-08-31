defmodule Game.NPC.ConversationTest do
  use Data.ModelCase

  alias Data.Script.Line
  alias Game.Channel
  alias Game.Message
  alias Game.NPC.Conversation
  alias Game.NPC.State
  alias Game.Quest

  describe "starting a new conversation" do
    setup do
      user = create_user()
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

      Channel.join_tell({:player, user})

      npc = %{npc | original_id: npc.id}
      %{user: user, npc: npc, state: %State{npc: npc}}
    end

    test "records the user and when they started", %{user: user, state: state} do
      state = Conversation.greet(state, user)

      assert %{key: "start", started_at: _} = Map.get(state.conversations, user.id)
      assert_receive {:channel, {:tell, {:npc, _}, %Message{message: "hello"}}}
    end
  end

  describe "continuing a conversation" do
    setup do
      user = create_user()
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

      Channel.join_tell({:player, user})

      state = %State{
        npc: npc,
        conversations: %{user.id => %{key: "start", script: npc.script}}
      }

      %{user: user, npc: npc, state: state}
    end

    test "receiving a message that matches the phrase", %{user: user, state: state} do
      state = Conversation.recv(state, user, "bandit")

      assert %{key: "bandits"} = Map.get(state.conversations, user.id)
      assert_receive {:channel, {:tell, {:npc, _}, %Message{message: "there are bandits near by"}}}
    end

    test "receiving a message that does not match the phrase", %{user: user, state: state} do
      state = Conversation.recv(state, user, "anything else")

      assert %{key: "start"} = Map.get(state.conversations, user.id)
      assert_receive {:channel, {:tell, {:npc, _}, %Message{message: "unknown"}}}
    end

    test "the unknown response is null - send nothing", %{user: user, state: state} do
      state = Conversation.recv(state, user, "bandit")
      state = Conversation.recv(state, user, "unknown")

      assert %{key: "bandits"} = Map.get(state.conversations, user.id)
      refute_receive {:channel, {:tell, {:npc, _}, %Message{message: nil}}}, 50
    end

    test "no previous conversation is considered a greeting", %{user: user, state: state} do
      state = %{state | conversations: %{}}

      state = Conversation.recv(state, user, "first time")

      assert %{key: "start"} = Map.get(state.conversations, user.id)
      assert_receive {:channel, {:tell, {:npc, _}, %Message{message: "hello"}}}
    end

    test "'finishing' a conversation clears out their key", %{user: user, state: state} do
      state = Conversation.recv(state, user, "done")

      refute Map.has_key?(state.conversations, user.id)
      assert_receive {:channel, {:tell, {:npc, _}, %Message{message: "conversation is over"}}}
    end
  end

  describe "quest giving npcs" do
    setup do
      user = create_user()
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

      Channel.join_tell({:player, user})

      state = %State{
        npc: %{npc | original_id: npc.id},
        conversations: %{user.id => %{key: "start", script: quest.script, quest_id: quest.id}},
      }

      %{user: user, npc: npc, state: state, quest: quest}
    end

    test "starting a new conversation and the npc is a quest giver with a new quest", %{user: user, state: state} do
      state = %{state | conversations: %{}}

      state = Conversation.greet(state, user)

      assert %{key: "start", started_at: _} = Map.get(state.conversations, user.id)
      assert_receive {:channel, {:tell, {:npc, _}, %Message{message: "a quest opener"}}}
    end

    test "gives the quest out when the conversation dictates it", %{user: user, state: state, quest: quest} do
      state = Conversation.recv(state, user, "bandit")

      assert is_nil(Map.get(state.conversations, user.id))
      assert_receive {:channel, {:tell, {:npc, _}, %Message{message: "there are bandits near by"}}}

      assert Quest.progress_for(user, quest.id)
    end
  end
end
