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
    state = %{channels: %{"global" => [self()]}, tells: %{"tells:10" => self(), "tells:11" => :pid}}
    {:noreply, state} = Channel.handle_info({:EXIT, self(), "quit"}, state)

    assert state == %{channels: %{"global" => []}, tells: %{"tells:11" => :pid}}
  end

  test "join the tell channel" do
    {:noreply, state} = Channel.handle_cast({:join_tell, self(), %{id: 10}}, %{tells: %{}})
    assert state.tells["tells:10"] == self()
  end

  test "receive a tell" do
    user = %{id: 10}
    from = %{id: 11}

    :ok = Channel.join_tell(user)

    Channel.tell(user, from, "hi")

    assert_receive {:channel, {:tell, ^from, "hi"}}
  end
end
