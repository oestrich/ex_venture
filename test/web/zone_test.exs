defmodule Web.ZoneTest do
  use Data.ModelCase

  alias Web.Room
  alias Web.Zone

  test "creating a new zone adds a child to the zone supervision tree" do
    params = %{name: "The Forest", description: "For level 1-4"}
    {:ok, zone} = Zone.create(params)

    pid = {:global, {Game.Zone, zone.id}}
    state = :sys.get_state(pid)

    assert state.zone.name == "The Forest"
  end

  test "updating a zone updates the gen server state for that zone" do
    {:ok, zone} = Zone.create(zone_attributes(%{name: "The Forest"}))
    {:ok, zone} = Zone.update(zone.id, %{name: "Forest"})

    pid = {:global, {Game.Zone, zone.id}}
    state = :sys.get_state(pid)

    assert state.zone.name == "Forest"
  end

  test "creating and deleting exits" do
    {:ok, room_zone} = Zone.create(zone_attributes(%{name: "The Forest"}))
    {:ok, room} = Room.create(room_zone, room_attributes(%{name: "Forest Path"}))

    {:ok, overworld_zone} = Zone.create(zone_attributes(%{name: "The Forest", type: "overworld"}))

    add_exits = [
      %{"direction" => "north", "start_overworld_id" => "overworld:#{overworld_zone.id}:1,1", "finish_room_id" => room.id},
    ]

    {:ok, zone} = Zone.modify_overworld_exits(overworld_zone, add_exits, [])

    assert length(zone.exits) == 1

    room_exit = List.first(zone.exits)
    {:ok, zone} = Zone.modify_overworld_exits(overworld_zone, [], [room_exit.id])

    assert length(zone.exits) == 0
  end
end
