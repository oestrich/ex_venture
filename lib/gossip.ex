defmodule Gossip do
  @moduledoc """
  Gossip client

  https://github.com/oestrich/gossip
  """

  @type channel :: String.t()

  @doc """
  Send a message to the Gossip network
  """
  @spec send(channel(), Message.t()) :: :ok
  def send(channel, message) do
    WebSockex.cast(Gossip.Socket, {:broadcast, channel, message})
  end
end
