defmodule Game.Zone.Sector do
  @moduledoc """
  Sector process
  """

  use GenServer

  @key :zones

  alias Game.Environment
  alias Game.Zone.Overworld

  def start_link(zone_id, sector) do
    GenServer.start_link(__MODULE__, [zone_id, sector], name: pid(zone_id, sector))
  end

  defp pid(zone_id, sector) do
    {:global, {Game.Zone.Sector, zone_id, sector}}
  end

  def init([zone_id, sector]) do
    state = %{
      zone_id: zone_id,
      sector: sector
    }

    {:ok, state}
  end

  def handle_call({:look, overworld_id}, _from, state) do
    {_zone_id, cell} = Overworld.split_id(overworld_id)

    {:ok, zone} = Cachex.get(@key, state.zone_id)

    environment = %Environment.State.Overworld{
      id: "overworld:" <> overworld_id,
      zone_id: state.zone_id,
      zone: zone.name,
      x: cell.x,
      y: cell.y,
      ecology: "default", # eventually from the editor
      exits: [], # determine based on the coordinate, then based on metadata for warp exits
      players: [],
      npcs: [],
    }

    {:reply, {:ok, environment}, state}
  end
end
