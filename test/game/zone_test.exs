defmodule Game.ZoneTest do
  use Data.ModelCase
  import Test.DoorHelper

  alias Game.Door
  alias Game.Zone

  setup do
    north = %{id: 1, x: 2, y: 1, map_layer: 1, exits: [%{direction: "south"}]}
    east = %{id: 2, x: 3, y: 2, map_layer: 1, exits: [%{direction: "west"}]}
    south = %{id: 3, x: 2, y: 3, map_layer: 1, exits: [%{direction: "north"}]}
    west = %{id: 4, x: 1, y: 2, map_layer: 1, exits: [%{direction: "east"}]}
    center = %{id: 5, x: 2, y: 2, map_layer: 1, exits: [%{direction: "north"}, %{direction: "east"}, %{direction: "south"}, %{direction: "west"}]}

    zone = %{type: "rooms", rooms: [north, east, south, west, center], name: "Bandit Hideout"}

    start_and_clear_doors()

    %{zone: zone, north: north}
  end

  describe "mapping" do
    test "displays a map - rooms", %{zone: zone} do
      {:reply, map, _} = Zone.handle_call({:map, {2, 2, 1}, []}, self(), %{zone: zone, rooms: zone.rooms})
      refute is_nil(map)
    end

    test "displays a map - overworld" do
      zone = %Data.Zone{name: "Deep Forest", type: "overworld", overworld_map: basic_overworld_map()}

      {:reply, map, _} = Zone.handle_call({:map, {2, 2}, []}, self(), %{zone: zone})

      refute is_nil(map)
    end
  end

  test "updates the local room" do
    {:noreply, state} = Zone.handle_cast({:update_room, %{id: 10, name: "Forest"}, self()}, %{rooms: [%{id: 10}], room_pids: []})
     room = state.rooms |> List.first
     assert room.name == "Forest"
  end

  test "when a room comes online and has a door it is initialized", %{north: north} do
    north = %{north | exits: [%{id: 1, has_door: true}]}

    {:noreply, _state} = Zone.handle_cast({:room_online, north, self()}, %{rooms: [], room_pids: []})

    assert Door.closed?(1)
  end

  test "returns the graveyard when one is set" do
    {:reply, {:ok, 2}, _state} = Zone.handle_call(:graveyard, {self(), make_ref()}, %{zone: %{graveyard_id: 2}})
  end

  test "returns an error when no graveyard is set" do
    {:reply, {:error, :no_graveyard}, _state} = Zone.handle_call(:graveyard, {self(), make_ref()}, %{zone: %{}})
  end
end
