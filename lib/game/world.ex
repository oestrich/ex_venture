defmodule Game.World do
  @moduledoc """
  Supervisor for the world

  Holds the zone supervisors
  """

  use Supervisor

  alias Game.Zone

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Spawn a new zone supervisor
  """
  @spec start_child(pid) :: {:ok, pid}
  def start_child(zone) do
    child_spec = supervisor(Zone.Supervisor, [zone], id: zone.id, restart: :permanent)
    Supervisor.start_child(__MODULE__, child_spec)
  end

  def init(_) do
    children = [
      {Game.World.Master, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
