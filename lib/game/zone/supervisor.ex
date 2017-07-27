defmodule Game.Zone.Supervisor do
  @moduledoc """
  Supervisor for Zones
  """

  use Supervisor

  alias Game.Zone

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Return all zones that are currently online
  """
  @spec zones() :: [pid]
  def zones() do
    Supervisor.which_children(__MODULE__)
    |> Enum.map(&(elem(&1, 1)))
  end

  def init(_) do
    children = Zone.all |> Enum.map(fn (zone) ->
      worker(Zone, [zone], id: zone.id, restart: :permanent)
    end)

    supervise(children, strategy: :one_for_one)
  end
end
