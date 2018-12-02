defmodule Game.NPC.Actions.CommandsSayTest do
  use Data.ModelCase

  alias Data.Events.Actions
  alias Game.NPC.Actions.CommandsSay

  doctest CommandsSay

  @room Test.Game.Room

  setup do
    @room.clear_says()

    %{state: %{npc: npc_attributes(%{id: 1}), room_id: 1}}
  end

  describe "acting" do
    test "speaks to the room", %{state: state} do
      action = %Actions.CommandsSay{
        options: %{message: "Hello"}
      }

      {:ok, ^state} = CommandsSay.act(state, action)

      [{_, message}] = @room.get_says()
      assert message.message == "Hello"
    end

    test "selects a random message", %{state: state} do
      action = %Actions.CommandsSay{
        options: %{messages: ["Hello"]}
      }

      {:ok, ^state} = CommandsSay.act(state, action)

      [{_, message}] = @room.get_says()
      assert message.message == "Hello"
    end
  end
end
