defmodule Game.NPC.Actions.CommandsSayTest do
  use ExVenture.NPCCase

  alias Data.Events.Actions
  alias Game.NPC.Actions.CommandsSay

  doctest CommandsSay

  setup do
    %{state: %{npc: npc_attributes(%{id: 1}), room_id: 1}}
  end

  describe "acting" do
    test "speaks to the room", %{state: state} do
      action = %Actions.CommandsSay{
        options: %{message: "Hello"}
      }

      {:ok, ^state} = CommandsSay.act(state, action)

      assert_say "hello"
    end

    test "selects a random message", %{state: state} do
      action = %Actions.CommandsSay{
        options: %{messages: ["Hello"]}
      }

      {:ok, ^state} = CommandsSay.act(state, action)

      assert_say "hello"
    end
  end

  describe "matching against the room id" do
    test "when matches", %{state: state} do
      action = %Actions.CommandsSay{
        options: %{
          room_id: 1,
          message: "Hello"
        }
      }

      {:ok, ^state} = CommandsSay.act(state, action)

      assert_say "hello"
    end

    test "when does not matches", %{state: state} do
      action = %Actions.CommandsSay{
        options: %{
          room_id: 2,
          message: "Hello"
        }
      }

      {:ok, ^state} = CommandsSay.act(state, action)

      refute_say()
    end
  end
end
