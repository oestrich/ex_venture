defmodule Data.RoomTest do
  use Data.ModelCase

  alias Data.Room

  test "determine exits" do
    exits = [%{north_id: 10, south_id: 1}, %{east_id: 11, west_id: 1}, %{north_id: 1, south_id: 12}, %{east_id: 1, west_id: 13}]
    room = %Room{id: 1, exits: exits}
    assert Room.exits(room) == ["north", "east", "south", "west"]

    exits = [%{north_id: 10, south_id: 1}, %{north_id: 1, south_id: 12}]
    room = %Room{id: 1, exits: exits}
    assert Room.exits(room) == ["north", "south"]
  end
end
