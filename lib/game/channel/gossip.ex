defmodule Game.Channel.Gossip do
  @moduledoc """
  Callback module for Gossip
  """

  alias Game.Channel
  alias Game.Channels
  alias Game.Message
  alias Game.Session

  @behaviour Gossip.Client

  @impl true
  def user_agent() do
    ExVenture.version()
  end

  @impl true
  def channels() do
    Enum.map(Channels.gossip_channels(), &(&1.gossip_channel))
  end

  @impl true
  def players() do
    Session.Registry.connected_players()
    |> Enum.map(&(&1.user.name))
  end

  @impl true
  def message_broadcast(message) do
    with {:ok, channel} <- Channels.gossip_channel(message.channel),
         true <- Raft.node_is_leader?() do
      message = Message.gossip_broadcast(channel, message)
      Channel.broadcast(channel.name, message)

      :ok
    else
      _ ->
        :ok
    end
  end
end
