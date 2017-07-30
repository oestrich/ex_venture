defmodule Game.Command.InfoTest do
  use Data.ModelCase

  alias Game.Command

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket}}
  end

  test "view room information", %{session: session, socket: socket} do
    user = %{name: "hero", save: %Data.Save{class: Game.Class.Fighter}}
    Command.Info.run({}, session, %{socket: socket, user: user})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(hero), look)
  end
end
