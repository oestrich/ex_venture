defmodule Game.NPC.Supervisor do
  @moduledoc """
  Supervisor for NPCs
  """

  use Supervisor

  alias Game.NPC

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Return all npcs that are currently online
  """
  @spec npcs() :: [pid]
  def npcs() do
    __MODULE__
    |> Supervisor.which_children()
    |> Enum.map(&(elem(&1, 1)))
  end

  def init(_) do
    children = NPC.all |> Enum.map(fn (npc) ->
      worker(NPC, [npc], id: npc.id, restart: :permanent)
    end)

    supervise(children, strategy: :one_for_one)
  end
end
