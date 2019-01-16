defmodule Web.ZoneTest do
  use Data.ModelCase

  alias Web.Zone

  test "creating a new zone adds a child to the zone supervision tree" do
    params = %{name: "The Forest", description: "For level 1-4"}
    {:ok, zone} = Zone.create(params)

    pid = {:global, {Game.Zone, zone.id}}
    state = :sys.get_state(pid)

    assert state.zone.name == "The Forest"
  end

  test "updating a zone updates the gen server state for that zone" do
    zone = create_zone()
    NamedProcess.start_link({Game.Zone, zone.id})

    {:ok, _zone} = Zone.update(zone.id, %{name: "Forest"})

    assert_receive {_, {:cast, {:update, _}}}
  end

  describe "overworld exits" do
    setup do
      room_zone = create_zone(%{name: "The Forest"})
      room = create_room(room_zone, %{name: "Forest Path"})

      overworld_zone = create_zone(%{name: "The Forest", type: "overworld"})
      NamedProcess.start_link({Game.Zone, overworld_zone.id})

      %{room: room, overworld_zone: overworld_zone}
    end

    test "creating an overworld exit", %{overworld_zone: overworld_zone, room: room} do
      new_exit = %{
        "direction" => "north",
        "start_overworld_id" => "overworld:#{overworld_zone.id}:1,1",
        "finish_room_id" => room.id
      }

      {:ok, zone, _room_exit} = Zone.add_overworld_exit(overworld_zone, new_exit)

      assert length(zone.exits) == 1
    end

    test "creating an overworld exit by cell location", %{overworld_zone: overworld_zone, room: room} do
      new_exit = %{
        "direction" => "north",
        "start_overworld" => %{"x" => 1, "y" => "1"},
        "finish_room_id" => room.id
      }

      {:ok, zone, _room_exit} = Zone.add_overworld_exit(overworld_zone, new_exit)

      assert length(zone.exits) == 1
    end

    test "deleting an overworld exit", %{overworld_zone: overworld_zone, room: room} do
      new_exit = %{
        "direction" => "north",
        "start_overworld_id" => "overworld:#{overworld_zone.id}:1,1",
        "finish_room_id" => room.id
      }
      {:ok, overworld_zone, room_exit} = Zone.add_overworld_exit(overworld_zone, new_exit)

      {:ok, overworld_zone} = Zone.delete_overworld_exit(overworld_zone, room_exit.id)

      assert length(overworld_zone.exits) == 0
    end
  end
end
