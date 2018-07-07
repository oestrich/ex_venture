defmodule Gossip do
  @moduledoc """
  Gossip client

  https://github.com/oestrich/gossip
  """

  @type channel :: String.t()

  @client_id Application.get_env(:ex_venture, :gossip)[:client_id]

  def configured?(), do: @client_id != nil

  def start_socket(), do: Gossip.Supervisor.start_socket()

  @doc """
  Send a message to the Gossip network
  """
  @spec broadcast(Gossip.Client.channel_name(), Gossip.Message.send()) :: :ok
  def broadcast(channel, message) do
    WebSockex.cast(Gossip.Socket, {:broadcast, channel, message})
  end
end
