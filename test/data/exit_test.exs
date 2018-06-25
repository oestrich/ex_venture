defmodule Data.ExitTest do
  use Data.ModelCase
  doctest Data.Exit

  alias Data.Exit
  alias Data.Room

  test "loads exits" do
    zone = create_zone()
    room = create_room(zone, %{x: 2, y: 2})

    north = create_room(zone, %{x: 2, y: 1})
    east = create_room(zone, %{x: 3, y: 2})
    south = create_room(zone, %{x: 2, y: 3})
    west = create_room(zone, %{x: 1, y: 2})
    up = create_room(zone, %{x: 1, y: 2, map_layer: 2})
    down = create_room(zone, %{x: 1, y: 2, map_layer: 3})

    create_exit(%{direction: "north", start_room_id: room.id, finish_room_id: north.id})
    create_exit(%{direction: "east", start_room_id: room.id, finish_room_id: east.id})
    create_exit(%{direction: "south", start_room_id: room.id, finish_room_id: south.id})
    create_exit(%{direction: "west", start_room_id: room.id, finish_room_id: west.id})
    create_exit(%{direction: "down", start_room_id: room.id, finish_room_id: down.id})
    create_exit(%{direction: "up", start_room_id: room.id, finish_room_id: up.id})

    room = Exit.load_exits(room)

    assert room.exits |> length() == 6
  end

  test "find an exit" do
    room = %Room{id: 10, exits: [%{direction: "south", start_room_id: 10, finish_room_id: 11}]}

    assert %{direction: "south"} = Exit.exit_to(room, "south")
  end

  describe "validate start/finish fields" do
    test "can only have one of the start fields" do
      changeset = Exit.changeset(%Exit{}, %{start_room_id: 1})
      refute changeset.errors[:start_room_id]

      changeset = Exit.changeset(%Exit{}, %{start_overworld_id: "overworld:1:1,1"})
      refute changeset.errors[:start_overworld_id]

      changeset = Exit.changeset(%Exit{}, %{start_room_id: 1, start_overworld_id: "overworld:1:1,1"})
      assert changeset.errors[:start_room_id]
      assert changeset.errors[:start_overworld_id]
    end

    test "can only have one of the finish fields" do
      changeset = Exit.changeset(%Exit{}, %{finish_room_id: 1})
      refute changeset.errors[:finish_room_id]

      changeset = Exit.changeset(%Exit{}, %{finish_overworld_id: "overworld:1:1,1"})
      refute changeset.errors[:finish_overworld_id]

      changeset = Exit.changeset(%Exit{}, %{finish_room_id: 1, finish_overworld_id: "overworld:1:1,1"})
      assert changeset.errors[:finish_room_id]
      assert changeset.errors[:finish_overworld_id]
    end
  end
end
