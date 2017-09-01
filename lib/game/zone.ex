defmodule Game.Zone do
  @moduledoc """
  Supervisor for Rooms
  """

  @type t :: %{
    name: String.t,
  }

  use GenServer

  alias Game.Map, as: GameMap
  alias Game.Room
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
  Start a new room in the supervision tree
  """
  @spec spawn_room(id :: integer, room :: Data.Room.t) :: :ok
  def spawn_room(id, room) do
    GenServer.cast(pid(id), {:spawn_room, room})
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
  @spec map(id :: integer, player_at :: {integer, integer}) :: String.t
  def map(id, player_at) do
    GenServer.call(pid(id), {:map, player_at})
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
    {:ok, %{zone: zone, rooms: [], room_supervisor_pid: nil}}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:map, player_at}, _from, state = %{zone: zone}) do
    map = """
    #{zone.name}

    #{GameMap.display_map(state, player_at)}
    """
    {:reply, map |> String.trim(), state}
  end

  def handle_cast({:tick, time}, state = %{rooms: rooms}) do
    rooms |> Enum.each(&(Room.tick(&1.id, time)))
    {:noreply, state}
  end

  def handle_cast({:room_online, room}, state = %{rooms: rooms}) do
    {:noreply, Map.put(state, :rooms, [room | rooms])}
  end

  def handle_cast({:update, zone}, state) do
    {:noreply, Map.put(state, :zone, zone)}
  end

  def handle_cast({:room_supervisor, pid}, state) do
    {:noreply, Map.put(state, :room_supervisor_pid, pid)}
  end

  def handle_cast({:spawn_room, room}, state = %{room_supervisor_pid: room_supervisor_pid}) do
    Room.Supervisor.start_child(room_supervisor_pid, room)
    {:noreply, state}
  end

  def handle_cast({:update_room, room}, state = %{rooms: rooms}) do
    rooms = rooms |> Enum.reject(&(&1.id == room.id))
    {:noreply, Map.put(state, :rooms, [room | rooms])}
  end
end
