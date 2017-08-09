defmodule Game.NPCTest do
  use Data.ModelCase

  @room Test.Game.Room

  alias Game.NPC

  test "being targeted makes the npc say something" do
    {:noreply, _state} = NPC.handle_cast({:targeted, %{name: "Player"}}, %{npc: %{name: "NPC", room_id: 1}})

    [{_, message}] = @room.get_says()
    assert message.message == "Why are you targeting me, Player?"
  end
end
