defmodule Data.RoomTest do
  use Data.ModelCase

  alias Data.Room

  test "determine exits" do
    exits = [
      %{direction: "north", start_id: 1, finish_id: 10},
      %{direction: "east",start_id: 1,  finish_id: 11},
      %{direction: "south", start_id: 1, finish_id: 12},
      %{direction: "west", start_id: 1, finish_id: 13},
      %{direction: "up", start_id: 1, finish_id: 14},
      %{direction: "down", start_id: 1, finish_id: 15},
    ]
    room = %Room{id: 1, exits: exits}
    assert Room.exits(room) == ["north", "east", "south", "west", "up", "down"]

    exits = [
      %{direction: "north", start_id: 1, finish_id: 10},
      %{direction: "south", start_id: 1, finish_id: 12},
    ]
    room = %Room{id: 1, exits: exits}
    assert Room.exits(room) == ["north", "south"]
  end
end
