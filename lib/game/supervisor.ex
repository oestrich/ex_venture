defmodule Game.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(Game.Server, []),
      supervisor(Game.Session.Supervisor, []),
      supervisor(Game.Zone, []),
      supervisor(Game.NPC.Supervisor, []),
      worker(Game.Items, []),
      worker(Game.Help, []),
    ]

    supervise(children, strategy: :one_for_one)
  end
end
