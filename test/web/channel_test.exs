defmodule Web.ChannelTest do
  use Data.ModelCase

  alias Game.Channels
  alias Web.Channel

  setup do
    Channels.clear()
    :ok
  end

  test "creating a class" do
    params = %{
      "name" => "fighters",
    }

    {:ok, channel} = Channel.create(params)

    assert channel.name == "fighters"
    assert "fighters" in Channels.get_channels()
  end
end
