defmodule Game.Session.Supervisor do
  @moduledoc """
  Supervisor for sessions
  """

  use Supervisor

  alias Game.Session

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc """
  Start a new session for a socket
  """
  @spec start_child(socket_pid :: pid) :: {:ok, pid}
  def start_child(socket_pid) do
    child_spec = worker(Session.Process, [socket_pid], [id: socket_pid, restart: :transient])
    Supervisor.start_child(__MODULE__, child_spec)
  end

  @doc false
  def init(_) do
    children = []
    supervise(children, strategy: :one_for_one)
  end
end
