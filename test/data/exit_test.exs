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

    create_exit(%{direction: "north", start_id: room.id, finish_id: north.id})
    create_exit(%{direction: "east", start_id: room.id, finish_id: east.id})
    create_exit(%{direction: "south", start_id: room.id, finish_id: south.id})
    create_exit(%{direction: "west", start_id: room.id, finish_id: west.id})
    create_exit(%{direction: "down", start_id: room.id, finish_id: down.id})
    create_exit(%{direction: "up", start_id: room.id, finish_id: up.id})

    room = Exit.load_exits(room)

    assert room.exits |> length() == 6
  end

  test "find an exit" do
    room = %Room{id: 10, exits: [%{direction: "south", start_id: 10, finish_id: 11}]}

    assert %{direction: "south"} = Exit.exit_to(room, :south)
  end
end
