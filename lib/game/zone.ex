defmodule Game.Zone do
  @moduledoc """
  Supervisor for Rooms
  """

  @type t :: %{
    name: String.t,
  }

  use GenServer

  alias Game.Room
  alias Game.Zone.Repo

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

  #
  # Server
  #

  def init(zone) do
    {:ok, %{zone: zone, rooms: []}}
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
end
