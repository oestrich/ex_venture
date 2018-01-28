defmodule Game.Supervisor do
  @moduledoc """
  Game Supervisor

  Loads the main server and all other supervisors required
  """
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(Game.Config, []),
      worker(Game.Server, []),
      supervisor(Game.Session.Supervisor, []),
      worker(Game.Door, []),
      worker(Game.Items, []),
      worker(Game.Skills, []),
      worker(Game.Channel, []),
      supervisor(Game.World, []),
      worker(Game.Insight, []),
      worker(Game.Help.Agent, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
