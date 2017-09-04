defmodule Game.NPC.Supervisor do
  @moduledoc """
  Supervisor for NPCs
  """

  use Supervisor

  alias Game.NPC
  alias Game.NPCSpawner
  alias Game.Zone

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

  @doc """
  Start a newly created npc in the zone
  """
  @spec start_child(pid, npc_spawner :: NPCSpawner.t) :: :ok
  def start_child(pid, npc_spawner) do
    child_spec = worker(NPC, [npc_spawner], id: npc_spawner.id, restart: :permanent)
    Supervisor.start_child(pid, child_spec)
  end

  def init(zone) do
    children = zone
    |> NPC.for_zone()
    |> Enum.map(fn (npc_spawner) ->
      worker(NPC, [npc_spawner], id: npc_spawner.id, restart: :permanent)
    end)

    Zone.npc_supervisor(zone.id, self())

    supervise(children, strategy: :one_for_one)
  end
end
