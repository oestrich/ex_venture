defmodule Game.Zone.SectorSupervisor do
  @moduledoc """
  Supervisor for zone overworld sectors
  """

  use Supervisor

  alias Game.Zone.Overworld
  alias Game.Zone.Sector

  def start_link(zone) do
    Supervisor.start_link(__MODULE__, zone, id: zone.id)
  end

  def init(zone) do
    children =
      zone.overworld_map
      |> Overworld.break_into_sectors()
      |> Enum.map(fn sector ->
        worker(Sector, [zone.id, sector], id: "sectors:#{zone.id}:#{sector}", restart: :permanent)
      end)

    supervise(children, strategy: :one_for_all)
  end
end
