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
      supervisor(Game.World, []),
      worker(Game.Channel, []),
      worker(Game.Items, []),
      worker(Game.Insight, []),
    ]

    supervise(children, strategy: :one_for_one)
  end
end
