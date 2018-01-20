defmodule Game.NPC.ConversationTest do
  use Data.ModelCase

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
        conversations: [
          %Data.Conversation{
            key: "start",
            message: "hello",
            listeners: [
              %{phrase: "next", key: "next"},
            ],
          },
          %Data.Conversation{
            key: "next",
            message: "hello",
          },
        ],
      })

      Channel.join_tell({:user, user})

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
        conversations: [
          %Data.Conversation{
            key: "start",
            message: "hello",
            unknown: "unknown",
            listeners: [
              %{phrase: "bandit", key: "bandits"},
              %{phrase: "done", key: "done"},
            ],
          },
          %Data.Conversation{
            key: "bandits",
            message: "there are bandits near by",
            listeners: [
              %{phrase: "done", key: "done"},
            ],
          },
          %Data.Conversation{
            key: "done",
            message: "conversation is over",
          },
        ],
      })

      Channel.join_tell({:user, user})

      state = %State{
        npc: npc,
        conversations: %{user.id => %{key: "start", conversations: npc.conversations}}
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
        conversations: [%Data.Conversation{key: "start", message: "hello"}],
      })

      quest = create_quest(npc, %{
        conversations: [
          %Data.Conversation{
            key: "start",
            message: "a quest opener",
            listeners: [
              %{phrase: "bandit", key: "bandits"},
            ],
          },
          %Data.Conversation{
            key: "bandits",
            message: "there are bandits near by",
            trigger: "quest",
          },
        ],
      })

      Channel.join_tell({:user, user})

      state = %State{
        npc: npc,
        conversations: %{user.id => %{key: "start", conversations: quest.conversations, quest_id: quest.id}},
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
