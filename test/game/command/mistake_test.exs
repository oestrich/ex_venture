defmodule Game.Command.MistakeTest do
  use ExUnit.Case
  doctest Game.Command.Mistake

  alias Game.Command.Mistake

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages
    %{session: :session, socket: :socket}
  end

  test "display a message about auto combat", %{session: session, socket: socket} do
    :ok = Mistake.run({:auto_combat}, session, %{socket: socket})

    [{^socket, echo}] = @socket.get_echos()
    assert Regex.match?(~r(read.*help), echo)
  end
end
