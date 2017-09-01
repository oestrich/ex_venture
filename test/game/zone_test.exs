defmodule Game.ZoneTest do
  use GenServerCase

  alias Game.Zone

  setup do
    north = %{x: 2, y: 1}
    east = %{x: 3, y: 2}
    south = %{x: 2, y: 3}
    west = %{x: 1, y: 2}
    center = %{x: 2, y: 2}

    zone = %{rooms: [north, east, south, west, center], name: "Bandit Hideout"}
    %{zone: zone}
  end

  test "displays a map", %{zone: zone} do
    {:reply, map, _} = Zone.handle_call({:map, {2, 2}}, self(), %{zone: zone, rooms: zone.rooms})
    assert map == "Bandit Hideout\n\n    [ ]    \n[ ] [X] [ ]\n    [ ]"
  end

  test "updates the local room" do
    {:noreply, state} = Zone.handle_cast({:update_room, %{id: 10, name: "Forest"}}, %{rooms: [%{id: 10}]})
     room = state.rooms |> List.first
     assert room.name == "Forest"
  end
end
