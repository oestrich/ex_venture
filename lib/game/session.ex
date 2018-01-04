defmodule Game.Session do
  @moduledoc """
  Client access to the `Game.Session.Process` GenServer.
  """

  @type t :: pid

  alias Data.User
  alias Game.Session.Supervisor

  @doc """
  Start a new session

  Creates a session pointing at a socket
  """
  @spec start(socket_pid :: pid) :: {:ok, pid}
  def start(socket) do
    Supervisor.start_child(socket)
  end

  @doc """
  Send a disconnect signal to a session
  """
  @spec disconnect(pid) :: :ok
  def disconnect(pid) do
    GenServer.cast(pid, :disconnect)
  end

  @doc """
  Send a disconnect signal to a session with options
  """
  @spec disconnect(pid, opts :: Keyword.t) :: :ok
  def disconnect(pid, opts) do
    GenServer.cast(pid, {:disconnect, opts})
  end

  @doc """
  Send a recv signal from the socket
  """
  @spec recv(pid, message :: String.t) :: :ok
  def recv(pid, message) do
    GenServer.cast(pid, {:recv, message})
  end

  @doc """
  Echo to the socket
  """
  @spec echo(pid, message :: String.t) :: :ok
  def echo(pid, message) do
    GenServer.cast(pid, {:echo, message})
  end

  @doc """
  Send a tick to the session
  """
  @spec tick(pid, time :: DateTime.t) :: :ok
  def tick(pid, time) do
    GenServer.cast(pid, {:tick, time})
  end

  @doc """
  Notify the session of an event, e.g. someone left the room
  """
  @spec notify(pid, action :: tuple()) :: :ok
  def notify(pid, action) do
    GenServer.cast(pid, {:notify, action})
  end

  @doc """
  Teleport the user to the room passed in
  """
  @spec teleport(pid, room_id :: integer) :: :ok
  def teleport(pid, room_id) do
    GenServer.cast(pid, {:teleport, room_id})
  end

  @doc """
  Sign in a user to a session, from the web client
  """
  @spec sign_in(pid(), User.t()) :: :ok
  def sign_in(pid, user) do
    GenServer.cast(pid, {:sign_in, user.id})
  end
end
