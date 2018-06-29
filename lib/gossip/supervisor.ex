defmodule Gossip.Supervisor do
  @moduledoc """
  Gossip Supervisor
  """
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(Gossip.Socket, []),
    ]

    supervise(children, strategy: :one_for_one)
  end
end
