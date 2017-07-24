defmodule Game.Registries do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      supervisor(Registry, [:duplicate, Game.Session.Registry], [id: Game.Session.Registry]),
      supervisor(Registry, [:unique, Game.Room.Registry], [id: Game.Room.Registry]),
      supervisor(Registry, [:unique, Game.NPC.Registry], [id: Game.NPC.Registry]),
    ]

    supervise(children, strategy: :one_for_one)
  end
end
