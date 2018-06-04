defmodule Game.Zone.Sector do
  @moduledoc """
  Sector process
  """

  use GenServer

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
end
