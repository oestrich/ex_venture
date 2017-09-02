defmodule Data.ExitTest do
  use Data.ModelCase
  doctest Data.Exit

  alias Data.Exit
  alias Data.Room

  test "can only have exits in one direction" do
    changeset = %Exit{} |> Exit.changeset(%{north_id: 1, south_id: 2})
    assert changeset.valid?

    changeset = %Exit{} |> Exit.changeset(%{east_id: 1, west_id: 2})
    assert changeset.valid?

    changeset = %Exit{} |> Exit.changeset(%{north_id: 1, west_id: 2})
    refute changeset.valid?
  end

  test "loads exits" do
    zone = create_zone()
    room = create_room(zone, %{x: 2, y: 2})

    north = create_room(zone, %{x: 2, y: 1})
    east = create_room(zone, %{x: 3, y: 2})
    south = create_room(zone, %{x: 2, y: 3})
    west = create_room(zone, %{x: 1, y: 2})

    create_exit(%{north_id: north.id, south_id: room.id})
    create_exit(%{east_id: east.id, west_id: room.id})
    create_exit(%{north_id: room.id, south_id: south.id})
    create_exit(%{east_id: room.id, west_id: west.id})

    room = Exit.load_exits(room)

    assert room.exits |> length() == 4
  end

  test "find an exit" do
    room = %Room{id: 10, exits: [%{north_id: 10, south_id: 11}]}

    assert %{north_id: 10, south_id: 11} = Exit.exit_to(room, :south)
  end
end
