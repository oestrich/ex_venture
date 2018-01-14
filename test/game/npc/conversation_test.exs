defmodule Game.NPC.ConversationTest do
  use Data.ModelCase

  alias Game.Channel
  alias Game.Message
  alias Game.NPC.Conversation
  alias Game.NPC.State

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
        conversations: %{user.id => %{key: "start"}}
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
end
