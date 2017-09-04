defmodule Game.Command.ChannelsTest do
  use ExUnit.Case
  doctest Game.Command.Channels

  alias Game.Channel
  alias Game.Command.Channels

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages
    %{session: :session, socket: :socket}
  end

  test "list out channels", %{session: session, socket: socket} do
    :ok = Channel.join("global")
    :ok = Channel.join("newbie")

    :ok = Channels.run({}, session, %{socket: socket})

    [{^socket, echo}] = @socket.get_echos()
    assert Regex.match?(~r(global), echo)
    assert Regex.match?(~r(newbie), echo)
  end
end
