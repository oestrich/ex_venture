defmodule Game.Command.ChannelsTest do
  use ExUnit.Case
  doctest Game.Command.Channels

  alias Game.Channel
  alias Game.Command.Channels
  alias Game.Message

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages
    user = %{id: 10, name: "Player", save: %{channels: ["global"]}}
    %{socket: :socket, user: user}
  end

  test "list out channels", %{socket: socket} do
    :ok = Channel.join("global")
    :ok = Channel.join("newbie")

    :ok = Channels.run({}, %{socket: socket})

    [{^socket, echo}] = @socket.get_echos()
    assert Regex.match?(~r(global), echo)
    assert Regex.match?(~r(newbie), echo)
  end

  test "send a message to a channel", %{socket: socket, user: user} do
    :ok = Channel.join("global")

    :ok = Channels.run({"global", "hello"}, %{socket: socket, user: user})

    assert_receive {:channel, {:broadcast, "global", %Message{message: "hello"}}}
  end

  test "does not send a message if the user is not subscribed to the channel", %{socket: socket, user: user} do
    :ok = Channel.join("newbie")

    :ok = Channels.run({"newbie", "hello"}, %{socket: socket, user: user})

    refute_receive {:channel, {:broadcast, "global", %Message{message: "hello"}}}
  end

  test "join a channel", %{socket: socket} do
    :ok = Channels.run({:join, "global"}, %{socket: socket, user: %{save: %{channels: []}}})

    assert_receive {:channel, {:joined, "global"}}
  end

  test "join a channel - already joined", %{socket: socket, user: user} do
    :ok = Channels.run({:join, "global"}, %{socket: socket, user: user})

    refute_receive {:channel, {:joined, "global"}}
  end

  test "limit to official channels on a join", %{socket: socket, user: user} do
    :ok = Channels.run({:join, "new-channel"}, %{socket: socket, user: user})

    refute_receive {:channel, {:joined, "new-channel"}}
  end

  test "leave a channel", %{socket: socket, user: user} do
    :ok = Channel.join("global")

    :ok = Channels.run({:leave, "global"}, %{socket: socket, user: user})

    assert_receive {:channel, {:left, "global"}}
  end

  test "leave a channel - no in channel", %{socket: socket, user: user} do
    :ok = Channels.run({:leave, "newbie"}, %{socket: socket, user: user})

    refute_receive {:channel, {:left, "newbie"}}
  end
end
