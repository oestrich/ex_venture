defmodule Game.Command.InfoTest do
  use Data.ModelCase

  alias Game.Command

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket}}
  end

  test "view room information", %{session: session, socket: socket} do
    Command.Info.run([], "info", session, %{socket: socket, user: %{name: "hero"}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(hero), look)
  end
end
