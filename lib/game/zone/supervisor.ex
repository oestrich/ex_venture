defmodule Game.Zone.Supervisor do
  @moduledoc """
  Supervisor for Zones
  """

  use Supervisor

  alias Game.Zone
  alias Game.NPC
  alias Game.Room

  def start_link(zone) do
    Supervisor.start_link(__MODULE__, zone, id: zone.id)
  end

  def init(zone) do
    children = [
      worker(Zone, [zone], id: zone.id, restart: :permanent),
      supervisor(Room.Supervisor, [zone], id: "rooms:#{zone.id}", restart: :permanent),
      supervisor(NPC.Supervisor, [zone], id: "npcs:#{zone.id}", restart: :permanent),
    ]

    supervise(children, strategy: :one_for_all)
  end
end
