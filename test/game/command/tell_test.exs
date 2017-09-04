defmodule Game.Command.TellTest do
  use ExUnit.Case
  doctest Game.Command.Tell

  alias Game.Channel
  alias Game.Command.Tell
  alias Game.Session

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages
    %{session: :session, socket: :socket, user: %{id: 10, name: "Player"}}
  end

  test "send a tell", %{session: session, socket: socket, user: user} do
    Channel.join_tell(user)
    Session.Registry.register(user)

    :ok = Tell.run({"tell", "player hello"}, session, %{socket: socket, user: user})

    assert_receive {:channel, {:tell, ^user, ~s[{blue}Player{/blue} tells you, {green}"hello"{/green}]}}
  end

  test "send a tell - player not found", %{session: session, socket: socket, user: user} do
    :ok = Tell.run({"tell", "player hello"}, session, %{socket: socket, user: user})

    [{^socket, echo}] = @socket.get_echos()
    assert Regex.match?(~r(not online), echo)
  end

  test "send a reply", %{session: session, socket: socket, user: user} do
    Channel.join_tell(user)
    Session.Registry.register(user)

    :ok = Tell.run({"reply", "howdy"}, session, %{socket: socket, user: user, reply_to: user})

    assert_receive {:channel, {:tell, ^user, ~s[{blue}Player{/blue} tells you, {green}"howdy"{/green}]}}
  end

  test "send a reply - player not online", %{session: session, socket: socket, user: user} do
    :ok = Tell.run({"reply", "howdy"}, session, %{socket: socket, user: user, reply_to: user})

    [{^socket, echo}] = @socket.get_echos()
    assert Regex.match?(~r(not online), echo)
  end

  test "send reply - no reply to", %{session: session, socket: socket, user: user} do
    :ok = Tell.run({"reply", "howdy"}, session, %{socket: socket, user: user, reply_to: nil})

    [{^socket, echo}] = @socket.get_echos()
    assert Regex.match?(~r(no one to reply), echo)
  end
end
