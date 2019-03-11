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
      {Game.PGNotifications, [name: Game.PGNotifications]},
      {Game.Session.Registry, [name: Game.Session.Registry]},
      {Game.Config, [name: Game.Config]},
      {Game.Caches, [name: Game.Caches]},
      {Game.Server, [name: Game.Server]},
      {Game.Session.Supervisor, [name: Game.Session.Supervisor]},
      {Game.Channel, [name: Game.Channel]},
      {Game.World, [name: Game.World]},
      {Game.Insight, [name: Game.Insight]},
      {Game.Help.Agent, [name: Game.Help.Agent]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
