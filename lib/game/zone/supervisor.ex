defmodule Game.Zone.Supervisor do
  @moduledoc """
  Supervisor for Zones
  """

  use Supervisor

  alias Game.Zone
  alias Game.NPC
  alias Game.Room
  alias Game.Shop

  def start_link(zone) do
    Supervisor.start_link(__MODULE__, zone, id: zone.id)
  end

  def init(zone) do
    supervise(children(zone), strategy: :one_for_all)
  end

  defp children(zone = %{type: "rooms"}) do
    [
      worker(Zone, [zone], id: zone.id, restart: :permanent),
      supervisor(Room.Supervisor, [zone], id: "rooms:#{zone.id}", restart: :permanent),
      supervisor(NPC.Supervisor, [zone], id: "npcs:#{zone.id}", restart: :permanent),
      supervisor(Shop.Supervisor, [zone], id: "shops:#{zone.id}", restart: :permanent)
    ]
  end

  defp children(zone = %{type: "overworld"}) do
    [
      worker(Zone, [zone], id: zone.id, restart: :permanent),
      supervisor(Zone.SectorSupervisor, [zone], id: "sectors:#{zone.id}", restart: :permanent),
    ]
  end
end
