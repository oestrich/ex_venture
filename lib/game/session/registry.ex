defmodule Game.Session.Registry do
  @moduledoc """
  Helper functions for the connected users registry
  """

  use GenServer

  alias Data.User
  alias Game.Character

  defmodule Metadata do
    @moduledoc """
    Struct for internal registry metadata
    """

    defstruct [:is_afk]
  end

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Register the session PID for the user
  """
  @spec register(User.t()) :: :ok
  def register(user) do
    GenServer.cast(__MODULE__, {:register, self(), user, %Metadata{is_afk: false}})
  end

  @doc """
  Update user's information, pulls out metadata from the session state
  """
  @spec update(User.t(), State.t()) :: :ok
  def update(user, state) do
    GenServer.cast(__MODULE__, {:update, self(), user, %Metadata{is_afk: state.is_afk}})
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

  @doc """
  Player has gone offline
  """
  @spec player_offline(User.t()) :: nil
  def player_offline(disconnecting_user) do
    connected_players()
    |> Enum.reject(fn %{user: user} ->
      user.id == disconnecting_user.id
    end)
    |> Enum.each(fn %{user: user} ->
      Character.notify({:user, user}, {"player/offline", disconnecting_user})
    end)
  end

  @doc """
  Player has come online
  """
  @spec player_online(User.t()) :: nil
  def player_online(connecting_user) do
    connected_players()
    |> Enum.reject(fn %{user: user} ->
      user.id == connecting_user.id
    end)
    |> Enum.each(fn %{user: user} ->
      Character.notify({:user, user}, {"player/online", connecting_user})
    end)
  end

  #
  # Server
  #

  def init(_) do
    Process.flag(:trap_exit, true)
    {:ok, %{connected_players: []}}
  end

  def handle_call(:connected_players, _from, state) do
    {:reply, state.connected_players, state}
  end

  def handle_cast(
        {:register, pid, user, metadata},
        state = %{connected_players: connected_players}
      ) do
    Process.link(pid)
    connected_players = [%{user: user, pid: pid, metadata: metadata} | connected_players]
    {:noreply, %{state | connected_players: connected_players}}
  end

  def handle_cast({:update, pid, user, metadata}, state = %{connected_players: connected_players}) do
    connected_players = [%{user: user, pid: pid, metadata: metadata} | connected_players]

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
