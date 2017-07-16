defmodule Data.RoomTest do
  use ExUnit.Case

  alias Data.Room

  test "determine exits" do
    room = %Room{north_id: 10, east_id: 11, south_id: 12, west_id: 13}
    assert Room.exits(room) == ["north", "east", "south", "west"]

    room = %Room{north_id: 10, south_id: 12}
    assert Room.exits(room) == ["north", "south"]
  end
end
