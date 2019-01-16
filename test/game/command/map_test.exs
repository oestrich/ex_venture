defmodule Game.Command.MapTest do
  use ExVenture.CommandCase

  alias Game.Command.Map

  doctest Map

  @room Test.Game.Room

  setup do
    @room.set_room(@room._room())
    %{socket: :socket}
  end

  test "view a map of the zone", %{socket: socket} do
    :ok = Map.run({}, %{socket: socket, save: %{room_id: 1}})

    assert_socket_echo "[ ]"
    assert_socket_gmcp {"Zone.Map", _}
  end
end
