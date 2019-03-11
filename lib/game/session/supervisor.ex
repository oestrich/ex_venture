defmodule Game.Session.Supervisor do
  @moduledoc """
  Supervisor for sessions
  """

  use DynamicSupervisor

  alias Game.Session

  @doc false
  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, nil, opts)
  end

  @doc """
  Start a new session for a socket
  """
  @spec start_child(pid) :: {:ok, pid}
  def start_child(socket_pid) do
    DynamicSupervisor.start_child(__MODULE__, {Session.Process, [socket_pid]})
  end

  @doc """
  Start a new session for a socket, that is sign_in
  """
  @spec start_child(pid(), integer()) :: {:ok, pid()}
  def start_child(socket_pid, player_id) do
    DynamicSupervisor.start_child(__MODULE__, {Session.Process, [socket_pid, player_id]})
  end

  @doc false
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
