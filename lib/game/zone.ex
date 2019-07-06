defmodule Game.Zone do
  @moduledoc """
  Supervisor for Rooms
  """

  @type t :: %{
          name: String.t()
        }

  use GenServer

  alias Game.Door
  alias Game.DoorLock
  alias Game.Map, as: GameMap
  alias Game.NPC
  alias Game.Overworld
  alias Game.Room
  alias Game.Shop
  alias Game.World.Master, as: WorldMaster
  alias Game.Zone.Repo, as: ZoneRepo

  @key :zones

  defmacro __using__(_opts) do
    quote do
      @zone Application.get_env(:ex_venture, :game)[:zone]
    end
  end

  def start_link(zone) do
    GenServer.start_link(__MODULE__, zone, name: pid(zone.id))
  end

  defp pid(id) do
    {:global, {Game.Zone, id}}
  end

  @doc """
  Return all zones
  """
  @spec all() :: [map]
  def all() do
    ZoneRepo.all()
  end

  #
  # Client
  #

  @doc """
  Let the zone know a room is online

  For sending ticks to
  """
  def room_online(id, room) do
    GenServer.cast(pid(id), {:room_online, room, self()})
  end

  @doc """
  Let the zone know a npc is online

  For sending ticks to
  """
  def npc_online(id, npc) do
    GenServer.cast(pid(id), {:npc_online, npc, self()})
  end

  @doc """
  Update a zone definition in the server state
  """
  @spec update(integer, Zone.t()) :: :ok
  def update(id, zone) do
    GenServer.cast(pid(id), {:update, zone})
  end

  @doc """
  Tell the zone where the room supervisor lives
  """
  @spec room_supervisor(integer, pid) :: :ok
  def room_supervisor(id, supervisor_pid) do
    GenServer.cast(pid(id), {:room_supervisor, supervisor_pid})
  end

  @doc """
  Tell the zone where the npc supervisor lives
  """
  @spec npc_supervisor(integer, pid) :: :ok
  def npc_supervisor(id, supervisor_pid) do
    GenServer.cast(pid(id), {:npc_supervisor, supervisor_pid})
  end

  @doc """
  Tell the zone where the shop supervisor lives
  """
  @spec shop_supervisor(integer, pid) :: :ok
  def shop_supervisor(id, supervisor_pid) do
    GenServer.cast(pid(id), {:shop_supervisor, supervisor_pid})
  end

  @doc """
  Start a new room in the supervision tree
  """
  @spec spawn_room(integer, Data.Room.t()) :: :ok
  def spawn_room(id, room) do
    GenServer.cast(pid(id), {:spawn_room, room})
  end

  @doc """
  Start a new npc in the supervision tree
  """
  @spec spawn_npc(integer, Data.NPCSpawner.t()) :: :ok
  def spawn_npc(id, npc_spawner) do
    GenServer.cast(pid(id), {:spawn_npc, npc_spawner})
  end

  @doc """
  Start a new shop in the supervision tree
  """
  @spec spawn_shop(integer, Data.Shop.t()) :: :ok
  def spawn_shop(id, shop) do
    GenServer.cast(pid(id), {:spawn_shop, shop})
  end

  @doc """
  Update a room's definition in the state

  For making sure mapping data stays correct on updates
  """
  @spec update_room(integer, Room.t()) :: :ok
  def update_room(id, room) do
    GenServer.cast(pid(id), {:update_room, room, self()})
  end

  @doc """
  Display a map of the zone
  """
  @spec map(integer, {integer, integer}, Keyword.t()) :: String.t()
  def map(id, player_at, opts \\ []) do
    GenServer.call(pid(id), {:map, player_at, opts})
  end

  @doc """
  Get a simple version of the zone
  """
  def name(id) do
    case Cachex.get(@key, id) do
      {:ok, zone} when zone != nil ->
        {:ok, zone}

      _ ->
        case ZoneRepo.get_name(id) do
          {:ok, zone} ->
            Cachex.put(@key, zone.id, zone)
            {:ok, zone}

          {:error, :unknown} ->
            {:error, :unknown}
        end
    end
  end

  @doc """
  Get the graveyard for a zone
  """
  def graveyard(id) do
    GenServer.call(pid(id), :graveyard)
  end

  @doc """
  Terminate a room process
  """
  def terminate_room(room) do
    GenServer.call(pid(room.zone_id), {:terminate, :room, room.id})
  end

  @doc """
  Crash a zone process with an unmatched cast

  There should always remain no matching clause for this cast
  """
  def crash(id) do
    GenServer.cast(pid(id), :crash)
  end

  @doc """
  For testing purposes, get the server's state
  """
  def _get_state(id) do
    GenServer.call(pid(id), :get_state)
  end

  #
  # Server
  #

  def init(zone) do
    Process.flag(:trap_exit, true)

    state = %{
      zone_id: zone.id,
      zone: nil,
      rooms: [],
      room_pids: [],
      room_supervisor_pid: nil,
      npcs: [],
      npc_pids: [],
      npc_supervisor_pid: nil,
      shop_supervisor_pid: nil
    }

    {:ok, state, {:continue, :load_zone}}
  end

  def handle_continue(:load_zone, state) do
    zone = ZoneRepo.get(state.zone_id)

    # Keep this the full zone for sector access
    WorldMaster.update_cache(@key, zone)

    {:noreply, %{state | zone: zone}}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:graveyard, _from, state) do
    case state.zone do
      %{graveyard_id: graveyard_id} when graveyard_id != nil ->
        {:reply, {:ok, graveyard_id}, state}

      _ ->
        {:reply, {:error, :no_graveyard}, state}
    end
  end

  def handle_call({:map, player_at, opts}, _from, state = %{zone: zone}) do
    case zone.type do
      "rooms" ->
        map = """
        #{zone.name}

        #{GameMap.display_map(state, player_at, opts)}
        """

        {:reply, map |> String.trim(), state}

      "overworld" ->
        {x, y} = player_at
        cell = %{x: x, y: y}

        map = """
        #{zone.name}

        #{Overworld.map(zone, cell)}
        """

        {:reply, map |> String.trim(), state}
    end
  end

  def handle_call({:terminate, :room, room_id}, _from, state) do
    Supervisor.terminate_child(state.room_supervisor_pid, room_id)
    {:reply, :ok, state}
  end

  def handle_cast({:room_online, room, room_pid}, state) do
    Process.link(room_pid)
    Enum.each(room.exits, &Door.maybe_load/1)
    Enum.each(room.exits, &DoorLock.maybe_load/1)

    state =
      state
      |> Map.put(:rooms, [room | state.rooms])
      |> Map.put(:room_pids, [{room_pid, room.id} | state.room_pids])

    {:noreply, state}
  end

  def handle_cast({:npc_online, npc, npc_pid}, state) do
    Process.link(npc_pid)

    state =
      state
      |> Map.put(:npcs, [npc | state.npcs])
      |> Map.put(:npc_pids, [{npc_pid, npc.id} | state.npc_pids])

    {:noreply, state}
  end

  def handle_cast({:update, zone}, state) do
    WorldMaster.update_cache(@key, zone)

    {:noreply, Map.put(state, :zone, zone)}
  end

  def handle_cast({:room_supervisor, pid}, state) do
    {:noreply, Map.put(state, :room_supervisor_pid, pid)}
  end

  def handle_cast({:npc_supervisor, pid}, state) do
    {:noreply, Map.put(state, :npc_supervisor_pid, pid)}
  end

  def handle_cast({:shop_supervisor, pid}, state) do
    {:noreply, Map.put(state, :shop_supervisor_pid, pid)}
  end

  def handle_cast({:spawn_room, room}, state = %{room_supervisor_pid: room_supervisor_pid}) do
    Room.Supervisor.start_child(room_supervisor_pid, room)
    Room.Supervisor.start_bus(room_supervisor_pid, room)
    {:noreply, state}
  end

  def handle_cast({:spawn_npc, npc_spawner}, state = %{npc_supervisor_pid: npc_supervisor_pid}) do
    NPC.Supervisor.start_child(npc_supervisor_pid, npc_spawner)
    {:noreply, state}
  end

  def handle_cast({:spawn_shop, shop}, state = %{shop_supervisor_pid: shop_supervisor_pid}) do
    Shop.Supervisor.start_child(shop_supervisor_pid, shop)
    {:noreply, state}
  end

  def handle_cast({:update_room, new_room, room_pid}, state) do
    rooms = state.rooms |> Enum.reject(&(&1.id == new_room.id))
    room_pids = state.room_pids |> Enum.reject(fn {pid, _} -> pid == room_pid end)

    state =
      state
      |> Map.put(:rooms, [new_room | rooms])
      |> Map.put(:room_pids, [{room_pid, new_room.id} | room_pids])

    {:noreply, state}
  end

  # Clean out the crashed process from stored knowledge, whether npc or room
  # the NPC is crashing as well, so it will restart on its own
  # tell all connected players that the process crashed
  def handle_info({:EXIT, pid, _reason}, state) do
    {rooms, room_pids} = reject_room_by_pid(state, pid)
    {npcs, npc_pids} = reject_npc_by_pid(state, pid)

    state =
      state
      |> Map.put(:rooms, rooms)
      |> Map.put(:room_pids, room_pids)
      |> Map.put(:npcs, npcs)
      |> Map.put(:npc_pids, npc_pids)

    {:noreply, state}
  end

  defp reject_room_by_pid(state, pid) do
    case find_pid(state.room_pids, pid) do
      {_pid, room_id} ->
        case Enum.find(state.rooms, &(&1.id == room_id)) do
          nil ->
            {state.rooms, state.room_pids}

          room ->
            rooms = state.rooms |> Enum.reject(&(&1.id == room.id))
            room_pids = state.room_pids |> Enum.reject(&(elem(&1, 0) == pid))

            {rooms, room_pids}
        end

      nil ->
        {state.rooms, state.room_pids}
    end
  end

  defp reject_npc_by_pid(state, pid) do
    case find_pid(state.npc_pids, pid) do
      {_pid, npc_id} ->
        case Enum.find(state.npcs, &(&1.id == npc_id)) do
          nil ->
            {state.npcs, state.npc_pids}

          npc ->
            npcs = state.npcs |> Enum.reject(&(&1.id == npc.id))
            npc_pids = state.npc_pids |> Enum.reject(&(elem(&1, 0) == pid))

            {npcs, npc_pids}
        end

      nil ->
        {state.npcs, state.npc_pids}
    end
  end

  defp find_pid(pids, matching_pid) do
    Enum.find(pids, fn {pid, _} ->
      pid == matching_pid
    end)
  end
end
