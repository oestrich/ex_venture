defmodule Game.Session.Registry do
  @moduledoc """
  Helper functions for the connected players registry
  """

  use GenServer

  alias Data.User
  alias Game.Character

  @group :session

  @ets_key :session_registry
  @metadata_ets_key :session_registry_metadata

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
  Register a pending connection
  """
  @spec register_connection(String.t()) :: :ok
  def register_connection(id) do
    members = :pg2.get_members(@group)

    Enum.map(members, fn member ->
      GenServer.cast(member, {:register_connection, self(), id})
    end)
  end

  @doc """
  Load all connected players
  """
  @spec authorize_connection(User.t(), String.t()) :: :ok
  def authorize_connection(player, id) do
    GenServer.cast(__MODULE__, {:authorize, player, id})
  end

  @doc """
  Connection authorized, remove the id from the state
  """
  @spec remove_connection(String.t()) :: :ok
  def remove_connection(id) do
    members = :pg2.get_members(@group)

    Enum.map(members, fn member ->
      GenServer.cast(member, {:remove_connection, id})
    end)
  end

  @doc """
  Register the session PID for the player
  """
  @spec register(User.t()) :: :ok
  def register(player) do
    members = :pg2.get_members(@group)

    character = Character.Simple.from_player(player)

    Enum.map(members, fn member ->
      GenServer.cast(member, {:register, self(), character, %Metadata{is_afk: false}})
    end)
  end

  @doc """
  Update player's information, pulls out metadata from the session state
  """
  @spec update(User.t(), State.t()) :: :ok
  def update(player, state) do
    members = :pg2.get_members(@group)

    character = Character.Simple.from_player(player)

    Enum.map(members, fn member ->
      GenServer.cast(member, {:update, self(), character, %Metadata{is_afk: state.is_afk}})
    end)
  end

  @doc """
  Unregister the current session pid
  """
  @spec unregister() :: :ok
  def unregister() do
    members = :pg2.get_members(@group)

    Enum.map(members, fn member ->
      GenServer.cast(member, {:unregister, self()})
    end)
  end

  @doc """
  Load all connected players
  """
  @spec connected_players() :: [{pid, User.t()}]
  def connected_players() do
    @ets_key
    |> :ets.match_object({:"$1", :"$2"})
    |> Enum.map(&elem(&1, 1))
  end

  @doc """
  Get the current player count

  Cached in ETS. Updated when players come and go
  """
  def player_count() do
    case :ets.lookup(@metadata_ets_key, :player_count) do
      [{_id, count}] ->
        count

      _ ->
        0
    end
  end

  @doc """
  Get the current admin count

  Cached in ETS. Updated when admins come and go
  """
  def admin_count() do
    case :ets.lookup(@metadata_ets_key, :admin_count) do
      [{_id, count}] ->
        count

      _ ->
        0
    end
  end

  @doc """
  Check if a player is online or not
  """
  @spec player_online?(User.t()) :: boolean()
  def player_online?(player) do
    case :ets.lookup(@ets_key, player.id) do
      [{_id, _player}] ->
        true

      _ ->
        false
    end
  end

  @doc """
  Find a connected player by their player struct
  """
  @spec find_connected_player(integer()) :: pid()
  @spec find_connected_player(User.t()) :: pid()
  def find_connected_player(player_id) when is_integer(player_id) do
    case :ets.lookup(@ets_key, player_id) do
      [{_id, player_state}] ->
        player_state

      _ ->
        nil
    end
  end

  def find_connected_player([name: player_name]) do
    connected_players()
    |> Enum.find(fn %{player: player} ->
      player.name |> String.downcase() == player_name |> String.downcase()
    end)
  end

  def find_connected_player(player) do
    find_connected_player(player.id)
  end

  @doc """
  Player has gone offline
  """
  @spec player_offline(User.t()) :: nil
  def player_offline(disconnecting_player) do
    Gossip.player_sign_out(disconnecting_player.name)

    connected_players()
    |> Enum.reject(fn %{player: player} ->
      player.id == disconnecting_player.id
    end)
    |> Enum.each(fn %{player: player} ->
      Character.notify({:player, player}, {"player/offline", disconnecting_player})
    end)
  end

  @doc """
  Player has come online
  """
  @spec player_online(User.t()) :: nil
  def player_online(connecting_player) do
    Gossip.player_sign_in(connecting_player.name)

    connected_players()
    |> Enum.reject(fn %{player: player} ->
      player.id == connecting_player.id
    end)
    |> Enum.each(fn %{player: player} ->
      Character.notify({:player, player}, {"player/online", connecting_player})
    end)
  end

  @doc """
  Find a connected player by name
  """
  @spec find_player(String.t()) :: {:ok, map()} | {:error, :not_found}
  def find_player(to_player) do
    player =
      connected_players()
      |> Enum.find(fn %{player: player} ->
        player.name |> String.downcase() == to_player |> String.downcase()
      end)

    case player do
      nil ->
        {:error, :not_found}

      player ->
        {:ok, player.player}
    end
  end

  @doc """
  For testing only

  Performs a call to allow for tests to ensure this is caught up
  """
  def catch_up() do
    GenServer.call(__MODULE__, {:catch_up})
  end

  #
  # Server
  #

  def init(_) do
    :ok = :pg2.create(@group)
    :ok = :pg2.join(@group, self())

    :ets.new(@ets_key, [:set, :protected, :named_table, read_concurrency: true])
    :ets.new(@metadata_ets_key, [:set, :protected, :named_table, read_concurrency: true])

    Process.flag(:trap_exit, true)
    {:ok, %{connected_players: [], connections: []}}
  end

  def handle_call({:catch_up}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast({:register_connection, pid, id}, state) do
    %{connections: connections} = state
    Process.link(pid)
    connections = [%{id: id, pid: pid} | connections]
    {:noreply, %{state | connections: connections}}
  end

  def handle_cast({:authorize, player, id}, state) do
    connection =
      state.connections
      |> Enum.find(fn connection ->
        connection.id == id
      end)

    case connection do
      nil ->
        {:noreply, state}

      connection ->
        remove_connection(id)

        send(connection.pid, {:authorize, player})

        {:noreply, state}
    end
  end

  def handle_cast({:remove_connection, id}, state) do
    connections = Enum.reject(state.connections, &(&1.id == id))
    {:noreply, %{state | connections: connections}}
  end

  def handle_cast({:register, pid, player, metadata}, state) do
    Process.link(pid)

    # Remove the player from the list, slight chance this was a double registration
    # Consider the new session theirs
    connected_players = Enum.reject(state.connected_players, &(&1.player.id == player.id))
    player_state = %{player: player, pid: pid, metadata: metadata}
    connected_players = [player_state | connected_players]

    :ets.insert(@ets_key, {player.id, player_state})

    update_counts(connected_players)

    {:noreply, %{state | connected_players: connected_players}}
  end

  def handle_cast({:update, pid, player, metadata}, state = %{connected_players: connected_players}) do
    player_ids = Enum.map(state.connected_players, &(&1.player.id))

    case player.id in player_ids do
      true ->
        player_state = %{player: player, pid: pid, metadata: metadata}
        connected_players = [player_state | connected_players]

        :ets.insert(@ets_key, {player.id, player_state})

        connected_players =
          connected_players
          |> Enum.uniq_by(& &1.pid)

        {:noreply, %{state | connected_players: connected_players}}

      false ->
        # Ignore updates for unregistered player
        {:noreply, state}
    end
  end

  def handle_cast({:unregister, pid}, state) do
    player_state =
      state.connected_players
      |> Enum.find(&(&1.pid == pid))

    if player_state do
      :ets.delete(@ets_key, player_state.player.id)
    end

    connected_players =
      state.connected_players
      |> Enum.reject(&(&1.pid == pid))

    connections =
      state.connections
      |> Enum.reject(&(&1.pid == pid))

    update_counts(connected_players)

    state =
      state
      |> Map.put(:connections, connections)
      |> Map.put(:connected_players, connected_players)

    {:noreply, state}
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    handle_cast({:unregister, pid}, state)
  end

  defp update_counts(connected_players) do
    {admins, players} = Enum.split_with(connected_players, &User.is_admin?(&1.player.extra))

    :ets.insert(@metadata_ets_key, {:admin_count, length(admins)})
    :ets.insert(@metadata_ets_key, {:player_count, length(players)})
  end
end
