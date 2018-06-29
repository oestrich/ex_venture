defmodule Gossip.Supervisor do
  @moduledoc """
  Gossip Supervisor
  """
  use Supervisor

  @client_id Application.get_env(:ex_venture, :gossip)[:client_id]

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    case @client_id do
      nil ->
        supervise([], strategy: :one_for_one)

      _ ->
        children = [
          worker(Gossip.Socket, [], name: Gossip.Socket, restart: :transient),
        ]

        supervise(children, strategy: :one_for_one)
    end
  end
end
