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
  Start a newly created npc in the zone
  """
  @spec start_child(pid, NPCSpawner.t()) :: :ok
  def start_child(pid, npc_spawner) do
    child_spec = worker(NPC, [npc_spawner.id], id: npc_spawner.id, restart: :transient)
    Supervisor.start_child(pid, child_spec)
  end

  def init(zone) do
    children =
      zone
      |> NPC.for_zone()
      |> Enum.map(fn npc_spawner_id ->
        worker(NPC, [npc_spawner_id], id: npc_spawner_id, restart: :transient)
      end)

    Zone.npc_supervisor(zone.id, self())

    supervise(children, strategy: :one_for_one)
  end
end
