defmodule Game.Zone do
  @moduledoc """
  Supervisor for Rooms
  """

  @type t :: %{
    name: String.t,
  }

  use GenServer

  alias Game.Door
  alias Game.Map, as: GameMap
  alias Game.NPC
  alias Game.Room
  alias Game.Shop
  alias Game.Zone.Repo

  defmacro __using__(_opts) do
    quote do
      @zone Application.get_env(:ex_venture, :game)[:zone]
    end
  end

  def start_link(zone) do
    GenServer.start_link(__MODULE__, zone, name: pid(zone.id))
  end

  defp pid(id) do
    {:via, Registry, {Game.Zone.Registry, id}}
  end

  @doc """
  Return all zones
  """
  @spec all() :: [map]
  def all() do
    Repo.all()
  end

  #
  # Client
  #

  @doc """
  Send a tick to the zone
  """
  @spec tick(pid, time :: DateTime.t) :: :ok
  def tick(pid, time) do
    GenServer.cast(pid, {:tick, time})
  end

  @doc """
  Let the zone know a room is online

  For sending ticks to
  """
  def room_online(id, room) do
    GenServer.cast(pid(id), {:room_online, room})
  end

  @doc """
  Let the zone know a npc is online

  For sending ticks to
  """
  def npc_online(id, npc) do
    GenServer.cast(pid(id), {:npc_online, npc})
  end

  @doc """
  Update a zone definition in the server state
  """
  @spec update(id :: integer, zone :: Zone.t) :: :ok
  def update(id, zone) do
    GenServer.cast(pid(id), {:update, zone})
  end

  @doc """
  Tell the zone where the room supervisor lives
  """
  @spec room_supervisor(id :: integer, supervisor_pid :: pid) :: :ok
  def room_supervisor(id, supervisor_pid) do
    GenServer.cast(pid(id), {:room_supervisor, supervisor_pid})
  end

  @doc """
  Tell the zone where the npc supervisor lives
  """
  @spec npc_supervisor(id :: integer, supervisor_pid :: pid) :: :ok
  def npc_supervisor(id, supervisor_pid) do
    GenServer.cast(pid(id), {:npc_supervisor, supervisor_pid})
  end

  @doc """
  Tell the zone where the shop supervisor lives
  """
  @spec shop_supervisor(id :: integer, supervisor_pid :: pid) :: :ok
  def shop_supervisor(id, supervisor_pid) do
    GenServer.cast(pid(id), {:shop_supervisor, supervisor_pid})
  end

  @doc """
  Start a new room in the supervision tree
  """
  @spec spawn_room(id :: integer, room :: Data.Room.t) :: :ok
  def spawn_room(id, room) do
    GenServer.cast(pid(id), {:spawn_room, room})
  end

  @doc """
  Start a new npc in the supervision tree
  """
  @spec spawn_npc(id :: integer, npc_spawner :: Data.Room.t) :: :ok
  def spawn_npc(id, npc_spawner) do
    GenServer.cast(pid(id), {:spawn_npc, npc_spawner})
  end

  @doc """
  Start a new shop in the supervision tree
  """
  @spec spawn_shop(id :: integer, shop :: Data.Shop.t) :: :ok
  def spawn_shop(id, shop) do
    GenServer.cast(pid(id), {:spawn_shop, shop})
  end

  @doc """
  Update a room's definition in the state

  For making sure mapping data stays correct on updates
  """
  @spec update_room(id :: integer, room :: Room.t) :: :ok
  def update_room(id, room) do
    GenServer.cast(pid(id), {:update_room, room})
  end

  @doc """
  Display a map of the zone
  """
  @spec map(id :: integer, player_at :: {integer, integer}, opts :: Keyword.t) :: String.t
  def map(id, player_at, opts \\ []) do
    GenServer.call(pid(id), {:map, player_at, opts})
  end

  @doc """
  Get the graveyard for a zone
  """
  def graveyard(id) do
    GenServer.call(pid(id), :graveyard)
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
    {:ok, %{zone: zone, rooms: [], room_supervisor_pid: nil, npcs: [], npc_supervisor_pid: nil, shop_supervisor_pid: nil}}
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
    map = """
    #{zone.name}

    #{GameMap.display_map(state, player_at, opts)}
    """
    {:reply, map |> String.trim(), state}
  end

  def handle_cast({:tick, time}, state = %{rooms: rooms, npcs: npcs}) do
    rooms |> Enum.each(&(Room.tick(&1.id, time)))
    npcs |> Enum.each(&(NPC.tick(&1.id, time)))
    {:noreply, state}
  end

  def handle_cast({:room_online, room}, state = %{rooms: rooms}) do
    Enum.each(room.exits, &Door.maybe_load/1)
    {:noreply, Map.put(state, :rooms, [room | rooms])}
  end

  def handle_cast({:npc_online, npc}, state = %{npcs: npcs}) do
    {:noreply, Map.put(state, :npcs, [npc | npcs])}
  end

  def handle_cast({:update, zone}, state) do
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

  def handle_cast({:update_room, room}, state = %{rooms: rooms}) do
    rooms = rooms |> Enum.reject(&(&1.id == room.id))
    {:noreply, Map.put(state, :rooms, [room | rooms])}
  end
end
