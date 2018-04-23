defmodule Game.World.Master do
  @moduledoc """
  Master process for the world

  Help orchestrate startup of zones
  """

  use GenServer

  alias Game.World
  alias Game.Zone

  require Logger

  @start_world Application.get_env(:ex_venture, :game)[:world]

  def leader_selected() do
    if @start_world do
      GenServer.cast(__MODULE__, :start_zones)
    end
  end

  def start_zone(pid, zone) do
    GenServer.cast(pid, {:start, zone})
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :ok = :pg2.create(:world)
    :ok = :pg2.join(:world, self())

    {:ok, %{leader: nil}}
  end

  def handle_cast({:start, zone}, state) do
    Logger.info("Starting zone #{zone.id}")
    World.start_child(zone)
    {:noreply, state}
  end

  # This is started by the raft
  def handle_cast(:start_zones, state) do
    Logger.info("Starting zones")
    start_zones()

    {:noreply, state}
  end

  defp start_zones() do
    members = :pg2.get_members(:world)

    Zone.all()
    |> Enum.with_index()
    |> Enum.each(fn {zone, index} ->
      member = Enum.at(members, rem(index, length(members)))
      __MODULE__.start_zone(member, zone)
    end)
  end
end
