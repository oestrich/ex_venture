defmodule Game.Command.MapTest do
  use Data.ModelCase

  alias Game.Command

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    @room.set_room(@room._room())
    @socket.clear_messages
    %{session: :session, socket: :socket}
  end

  test "view a map of the zone", %{session: session, socket: socket} do
    :ok = Command.Map.run({}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, map}] = @socket.get_echos()
    assert Regex.match?(~r([ ]), map)
    assert [{^socket, "Zone.Map", _}] = @socket.get_push_gmcps()
  end
end
