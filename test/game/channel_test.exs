defmodule Game.ChannelTest do
  use Data.ModelCase

  alias Game.Channel

  test "joining a channel" do
    :ok = Channel.join("global")

    assert_receive {:channel, {:joined, "global"}}
  end

  test "leave a channel" do
    :ok = Channel.join("global")
    :ok = Channel.leave("global")

    assert_receive {:channel, {:left, "global"}}
  end

  test "sending a message on the channel" do
    :ok = Channel.join("global")

    Channel.broadcast("global", "sending a message")

    assert_receive {:channel, {:broadcast, "sending a message"}}
  end

  test "list out subscribed channels" do
    :ok = Channel.join("global")

    assert Channel.subscribed() == ["global"]
  end

  test "removing a pid after an exit is trapped" do
    {:noreply, state} = Channel.handle_info({:EXIT, self(), "quit"}, %{channels: %{"global" => [self()]}})

    assert state == %{channels: %{"global" => []}}
  end
end
