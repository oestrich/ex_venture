defmodule Game.ChannelTest do
  use Data.ModelCase

  alias Data.ChannelMessage
  alias Game.Channel

  setup do
    Game.Channels.clear()
    channel = create_channel("global")
    channel |> insert_channel()

    %{channel: channel}
  end

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

    message = %{
      sender: %{id: 1, name: "player"},
      message: "sending a message",
      formatted: "sending a message",
    }

    Channel.broadcast("global", message)

    assert_receive {:channel, {:broadcast, "global", %{formatted: "sending a message"}}}
  end

  test "broadcasting a message records it", %{channel: channel} do
    user = create_user(%{name: "player", password: "password"})
    character = create_character(user, %{name: "player"})

    message = %{
      channel_id: channel.id,
      sender: character,
      message: "sending a message",
      formatted: "sending a message",
    }

    Channel.broadcast("global", message)

    Test.ChannelsHelper.ensure_process_caught_up(Channel)

    assert ChannelMessage |> Repo.all() |> length() == 1
  end

  test "list out subscribed channels" do
    :ok = Channel.join("global")

    assert [%{name: "global"}] = Channel.subscribed()
  end

  test "removing a pid after an exit is trapped" do
    state = %{channels: %{"global" => [self()]}, tells: %{"tells:10" => self(), "tells:11" => :pid}}
    {:noreply, state} = Channel.handle_info({:EXIT, self(), "quit"}, state)

    assert state == %{channels: %{"global" => []}, tells: %{"tells:11" => :pid}}
  end

  test "join the tell channel" do
    {:noreply, state} = Channel.handle_cast({:join_tell, self(), %{type: "player", id: 10}}, %{tells: %{}})
    assert state.tells["tells:player:10"] == self()
  end

  test "receive a tell" do
    player = %{type: "player", id: 10}
    from = %{id: 11}

    :ok = Channel.join_tell(player)

    Channel.tell(player, from, "hi")

    assert_receive {:channel, {:tell, ^from, "hi"}}
  end
end
