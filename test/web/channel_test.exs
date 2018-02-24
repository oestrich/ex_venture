defmodule Web.ChannelTest do
  use Data.ModelCase

  alias Game.Channels
  alias Web.Channel

  setup do
    Channels.clear()
    :ok
  end

  test "creating a channel" do
    params = %{
      "name" => "fighters",
      "color" => "yellow",
    }

    {:ok, channel} = Channel.create(params)

    assert channel.name == "fighters"
    assert Channels.get("fighters").color == "yellow"
    assert [%{name: "fighters"}] = Channels.all()
  end

  test "updating a channel" do
    params = %{
      "name" => "fighters",
      "color" => "yellow",
    }

    {:ok, channel} = Channel.create(params)
    {:ok, channel} = Channel.update(channel, %{"color" => "magenta"})

    assert channel.color == "magenta"
    assert Channels.get("fighters").color == "magenta"
  end
end
