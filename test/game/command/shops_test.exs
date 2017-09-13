defmodule Game.Command.ShopsTest do
  use Data.ModelCase

  @socket Test.Networking.Socket
  @room Test.Game.Room

  alias Game.Command

  setup do
    tree_stand = %{id: 10, name: "Tree Stand Shop"}
    hole_wall = %{id: 11, name: "Hole in the Wall"}
    room = %{@room._room() | shops: [tree_stand, hole_wall]}
    @room.set_room(room)
    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket, room: room}}
  end

  test "view shops in the room", %{session: session, socket: socket} do
    Command.Shops.run({}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Tree Stand Shop), look)
    assert Regex.match?(~r(Hole in the Wall), look)
  end
end
