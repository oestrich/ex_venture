defmodule Game.NPCSupervisor do
  @moduledoc """
  Supervisor for NPCs
  """

  use Supervisor

  alias Game.NPC

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = NPC.all |> Enum.map(fn (npc) ->
      worker(NPC, [npc], id: npc.id, restart: :permanent)
    end)

    supervise(children, strategy: :one_for_one)
  end
end
