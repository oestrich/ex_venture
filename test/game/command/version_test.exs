defmodule Game.Command.VersionTest do
  use ExUnit.Case
  doctest Game.Command.Version

  alias Game.Command.Version

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages
    %{socket: :socket}
  end

  test "view the version", %{socket: socket} do
    :ok = Version.run({}, %{socket: socket})

    [{^socket, echo}] = @socket.get_echos()
    assert Regex.match?(~r(ExVenture v), echo)
  end
end
