defmodule Game.Session do
  @moduledoc """
  Client access to the `Game.Session.Process` GenServer.
  """

  @type t :: pid

  alias Data.User
  alias Game.Character
  alias Game.Session
  alias Game.Session.Supervisor
  alias Game.World.Master, as: WorldMaster

  @doc """
  Start a new session

  Creates a session pointing at a socket
  """
  @spec start(pid) :: {:ok, pid}
  def start(socket) do
    Supervisor.start_child(socket)
  end

  @doc """
  Start a new session that is signed in

  Creates a session pointing at a socket
  """
  @spec start_with_user(pid, integer()) :: {:ok, pid}
  def start_with_user(socket, nil), do: start(socket)

  def start_with_user(socket, user_id) do
    Supervisor.start_child(socket, user_id)
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
  @spec disconnect(pid, Keyword.t()) :: :ok
  def disconnect(pid, opts) do
    GenServer.cast(pid, {:disconnect, opts})
  end

  @doc """
  Send a recv signal from the socket
  """
  @spec recv(pid, String.t()) :: :ok
  def recv(pid, message) do
    GenServer.cast(pid, {:recv, message})
  end

  @doc """
  Receive a GMCP request from the client
  """
  @spec recv_gmcp(pid(), String.t(), map()) :: :ok
  def recv_gmcp(pid, module, data \\ %{}) do
    GenServer.cast(pid, {:recv_gmcp, module, data})
  end

  @doc """
  Echo to the socket
  """
  @spec echo(pid, String.t()) :: :ok
  def echo(player = %User{}, message) do
    case find_connected_player(player) do
      nil ->
        :ok

      %{pid: pid} ->
        echo(pid, message)
    end
  end

  def echo(player = %Character.Simple{type: :player}, message) do
    case find_connected_player(player) do
      nil ->
        :ok

      %{pid: pid} ->
        echo(pid, message)
    end
  end

  def echo(pid, message) do
    GenServer.cast(pid, {:echo, message})
  end

  @doc """
  Send a tick to the session
  """
  @spec tick(pid, DateTime.t()) :: :ok
  def tick(pid, time) do
    GenServer.cast(pid, {:tick, time})
  end

  @doc """
  Notify the session of an event, e.g. someone left the room
  """
  @spec notify(pid, tuple()) :: :ok
  def notify(player = %User{}, action) do
    case find_connected_player(player) do
      nil ->
        :ok

      %{pid: pid} ->
        notify(pid, action)
    end
  end

  def notify(player = %Character.Simple{type: :player}, action) do
    case find_connected_player(player) do
      nil ->
        :ok

      %{pid: pid} ->
        notify(pid, action)
    end
  end

  def notify(pid, action) do
    GenServer.cast(pid, {:notify, action})
  end

  @doc """
  Teleport the player to the room passed in
  """
  @spec teleport(pid, integer) :: :ok
  def teleport(pid, room_id) do
    GenServer.cast(pid, {:teleport, room_id})
  end

  @doc """
  Sign in a player to a session, from the web client
  """
  @spec sign_in(pid(), User.t()) :: :ok
  def sign_in(pid, player) do
    case WorldMaster.is_world_online?() do
      true ->
        GenServer.cast(pid, {:sign_in, player.id})

      false ->
        :ok
    end
  end

  @doc """
  Room crashed, rejoin if necessary
  """
  @spec room_crashed(integer(), integer()) :: :ok
  def room_crashed(pid, room_id) do
    GenServer.cast(pid, {:room_crashed, room_id})
  end

  @doc """
  Find a connected player by their player struct
  """
  @spec find_connected_player(User.t()) :: pid()
  def find_connected_player(player) do
    Session.Registry.connected_players()
    |> Enum.find(fn %{player: connected_player} ->
      connected_player.id == player.id
    end)
  end
end
