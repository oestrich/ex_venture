defmodule Game.Session.Registry do
  @moduledoc """
  Helper functions for the connected users registry
  """

  use GenServer

  alias Data.User

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Register the session PID for the user
  """
  @spec register(User.t()) :: :ok
  def register(user) do
    GenServer.cast(__MODULE__, {:register, self(), user})
  end

  @doc """
  Update user's information
  """
  @spec update(User.t()) :: :ok
  def update(user) do
    GenServer.cast(__MODULE__, {:update, self(), user})
  end

  @doc """
  Unregister the current session pid
  """
  @spec unregister() :: :ok
  def unregister() do
    GenServer.cast(__MODULE__, {:unregister, self()})
  end

  @doc """
  Load all connected players
  """
  @spec connected_players() :: [{pid, User.t()}]
  def connected_players() do
    GenServer.call(__MODULE__, :connected_players)
  end

  #
  # Server
  #

  def init(_) do
    Process.flag(:trap_exit, true)
    {:ok, %{connected_players: []}}
  end

  def handle_call(:connected_players, _from, state) do
    players =
      state.connected_players
      |> Enum.map(&{&1.pid, &1.user})

    {:reply, players, state}
  end

  def handle_cast({:register, pid, user}, state = %{connected_players: connected_players}) do
    Process.link(pid)
    connected_players = [%{user: user, pid: pid} | connected_players]
    {:noreply, %{state | connected_players: connected_players}}
  end

  def handle_cast({:update, pid, user}, state = %{connected_players: connected_players}) do
    connected_players = [%{user: user, pid: pid} | connected_players]

    connected_players =
      connected_players
      |> Enum.uniq_by(& &1.pid)

    {:noreply, %{state | connected_players: connected_players}}
  end

  def handle_cast({:unregister, pid}, state = %{connected_players: connected_players}) do
    connected_players =
      connected_players
      |> Enum.reject(&(&1.pid == pid))

    state =
      state
      |> Map.put(:connected_players, connected_players)

    {:noreply, state}
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    handle_cast({:unregister, pid}, state)
  end
end
