defmodule Game.World.ZoneController do
  @moduledoc """
  Start and stop zones
  """

  use GenServer

  require Logger

  alias Game.World

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_zone(pid, zone) do
    GenServer.cast(pid, {:start, zone})
  end

  def hosted_zones(pid) do
    GenServer.call(pid, :get_hosted_zones)
  end

  def init(_) do
    :ok = :pg2.create(:world)
    :ok = :pg2.join(:world, self())

    {:ok, %{zones: []}}
  end

  def handle_call(:get_hosted_zones, _from, state) do
    {:reply, state.zones, state}
  end

  def handle_cast({:start, zone}, state) do
    Logger.info("Starting zone #{zone.id}")
    World.start_child(zone)
    {:noreply, %{state | zones: [zone.id | state.zones]}}
  end
end
