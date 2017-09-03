defmodule Game.NPC.Supervisor do
  @moduledoc """
  Supervisor for NPCs
  """

  use Supervisor

  alias Game.NPC

  def start_link(zone) do
    Supervisor.start_link(__MODULE__, zone, id: zone.id)
  end

  @doc """
  Return all npcs that are currently online in a zone
  """
  @spec npcs(pid) :: [pid]
  def npcs(pid) do
    pid
    |> Supervisor.which_children()
    |> Enum.map(&(elem(&1, 1)))
  end

  def init(zone) do
    children = zone
    |> NPC.for_zone()
    |> Enum.map(fn (zone_npc) ->
      worker(NPC, [zone_npc], id: zone_npc.id, restart: :permanent)
    end)

    supervise(children, strategy: :one_for_one)
  end
end
