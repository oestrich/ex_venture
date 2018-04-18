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

  @doc """
  Return all zones that are currently online
  """
  @spec zones() :: [pid]
  def zones() do
    __MODULE__
    |> Supervisor.which_children()
    |> Enum.flat_map(fn {_id, pid, _type, _module} ->
      pid
      |> Supervisor.which_children()
      |> Enum.reject(&Regex.match?(~r(rooms|npcs|shops), to_string(elem(&1, 0))))
      |> Enum.map(&elem(&1, 1))
    end)
  end

  def init(_) do
    children = [
      {Game.World.Master, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
