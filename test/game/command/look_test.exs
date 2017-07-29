defmodule Game.Command.LookTest do
  use Data.ModelCase

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    @room.set_room(@room._room())
    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket}}
  end

  test "view room information", %{session: session, socket: socket} do
    Game.Command.Look.run([], session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Hallway), look)
    assert Regex.match?(~r(Exits), look)
    assert Regex.match?(~r(Items), look)
  end

  test "looking at an item", %{session: session, socket: socket} do
    Game.Command.Look.run(["short sword"], session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(A simple blade), look)
  end

  test "looking in a direction", %{session: session, socket: socket} do
    Game.Command.Look.run(["north"], session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Hallway), look)
  end
end
