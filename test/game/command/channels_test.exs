defmodule Game.Command.ChannelsTest do
  use ExUnit.Case
  doctest Game.Command.Channels

  alias Game.Channel
  alias Game.Command.Channels

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages
    user = %{id: 10, name: "Player", save: %{channels: ["global"]}}
    %{session: :session, socket: :socket, user: user}
  end

  test "list out channels", %{session: session, socket: socket} do
    :ok = Channel.join("global")
    :ok = Channel.join("newbie")

    :ok = Channels.run({}, session, %{socket: socket})

    [{^socket, echo}] = @socket.get_echos()
    assert Regex.match?(~r(global), echo)
    assert Regex.match?(~r(newbie), echo)
  end

  test "send a message to a channel", %{session: session, socket: socket, user: user} do
    :ok = Channel.join("global")

    :ok = Channels.run({"global", "hello"}, session, %{socket: socket, user: user})

    assert_receive {:channel, {:broadcast, "{red}[global]{/red} {blue}Player{/blue} says, {green}\"hello\"{/green}"}}
  end

  test "does not send a message if the user is not subscribed to the channel", %{session: session, socket: socket, user: user} do
    :ok = Channel.join("newbie")

    :ok = Channels.run({"newbie", "hello"}, session, %{socket: socket, user: user})

    refute_receive {:channel, {:broadcast, "{red}[newbie]{/red} {blue}Player{/blue} says, {green}\"hello\"{/green}"}}
  end

  test "join a channel", %{session: session, socket: socket} do
    :ok = Channels.run({:join, "global"}, session, %{socket: socket, user: %{save: %{channels: []}}})

    assert_receive {:channel, {:joined, "global"}}
  end

  test "join a channel - already joined", %{session: session, socket: socket, user: user} do
    :ok = Channels.run({:join, "global"}, session, %{socket: socket, user: user})

    refute_receive {:channel, {:joined, "global"}}
  end

  test "leave a channel", %{session: session, socket: socket, user: user} do
    :ok = Channel.join("global")

    :ok = Channels.run({:leave, "global"}, session, %{socket: socket, user: user})

    assert_receive {:channel, {:left, "global"}}
  end

  test "leave a channel - no in channel", %{session: session, socket: socket, user: user} do
    :ok = Channels.run({:leave, "newbie"}, session, %{socket: socket, user: user})

    refute_receive {:channel, {:left, "newbie"}}
  end
end
