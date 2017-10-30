defmodule Game.ZoneTest do
  use GenServerCase
  import Test.DoorHelper

  alias Game.Door
  alias Game.Zone

  setup do
    north = %{id: 1, x: 2, y: 1, map_layer: 1, exits: [%{north_id: 1, south_id: 5}]}
    east = %{id: 2, x: 3, y: 2, map_layer: 1, exits: [%{east_id: 2, west_id: 5}]}
    south = %{id: 3, x: 2, y: 3, map_layer: 1, exits: [%{north_id: 5, south_id: 3}]}
    west = %{id: 4, x: 1, y: 2, map_layer: 1, exits: [%{east_id: 5, west_id: 4}]}
    center = %{id: 5, x: 2, y: 2, map_layer: 1, exits: [%{north_id: 1, south_id: 5}, %{east_id: 2, west_id: 5}, %{north_id: 5, south_id: 3}, %{east_id: 5, west_id: 4}]}

    zone = %{rooms: [north, east, south, west, center], name: "Bandit Hideout"}

    start_and_clear_doors()

    %{zone: zone, north: north}
  end

  test "displays a map", %{zone: zone} do
    {:reply, map, _} = Zone.handle_call({:map, {2, 2, 1}, []}, self(), %{zone: zone, rooms: zone.rooms})
    refute is_nil(map)
  end

  test "updates the local room" do
    {:noreply, state} = Zone.handle_cast({:update_room, %{id: 10, name: "Forest"}}, %{rooms: [%{id: 10}]})
     room = state.rooms |> List.first
     assert room.name == "Forest"
  end

  test "when a room comes online and has a door it is initialized", %{north: north} do
    north = %{north | exits: [%{id: 1, has_door: true}]}

    {:noreply, _state} = Zone.handle_cast({:room_online, north}, %{rooms: []})

    assert Door.closed?(1)
  end
end
