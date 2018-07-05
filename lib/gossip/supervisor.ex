defmodule Gossip.Supervisor do
  @moduledoc """
  Gossip Supervisor
  """
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Start the Gossip socket

  Will only start if the client id is available
  """
  def start_socket() do
    if Gossip.configured?() do
      child_spec = worker(Gossip.Socket, [], id: Gossip.Socket, restart: :transient)
      Supervisor.start_child(Gossip.Supervisor.Tether, child_spec)
    end
  end

  def init(_) do
    children = [
      {Gossip.Monitor, []},
      {Gossip.Supervisor.Tether, []},
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end

  defmodule Tether do
    @moduledoc """
    An extra layer of protection for the websocket process dying.

    This supervisor will start with a blank child list to prevent the
    websocket process rippling up the supervision tree.
    """

    use Supervisor

    def start_link(_) do
      Supervisor.start_link(__MODULE__, [], name: __MODULE__)
    end

    def init(_) do
      Supervisor.init([], strategy: :one_for_one)
    end
  end
end
