defmodule Game.NPC.EventsTest do
  use Data.ModelCase

  @room Test.Game.Room

  alias Game.NPC.Events

  setup do
    @room.clear_says()
  end

  test "say something to the room when a player enters it" do
    npc_spawner = %{room_id: 1}
    npc = %{name: "Mayor", events: [%{type: "room/entered", action: "say", arguments: ["Hello"]}]}

    :ok = Events.act_on(%{npc_spawner: npc_spawner, npc: npc}, {:enter, {:user, :session, %{}}})

    [{_, message}] = @room.get_says()
    assert message.message == "Hello"
  end

  test "do nothing when an NPC enters the room" do
    npc_spawner = %{room_id: 1}
    npc = %{name: "Mayor", events: [%{type: "room/entered", action: "say", arguments: ["Hello"]}]}

    :ok = Events.act_on(%{npc_spawner: npc_spawner, npc: npc}, {:enter, {:npc, %{}}})

    assert @room.get_says() |> length() == 0
  end
end
