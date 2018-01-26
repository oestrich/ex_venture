defmodule Game.Command.MapTest do
  use Data.ModelCase
  doctest Game.Command.Map

  alias Game.Command.Map

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    @room.set_room(@room._room())
    @socket.clear_messages
    %{socket: :socket}
  end

  test "view a map of the zone", %{socket: socket} do
    :ok = Map.run({}, %{socket: socket, save: %{room_id: 1}})

    [{^socket, map}] = @socket.get_echos()
    assert Regex.match?(~r([ ]), map)
    assert [{^socket, "Zone.Map", _}] = @socket.get_push_gmcps()
  end
end
