defmodule Game.Shop.Supervisor do
  @moduledoc """
  Supervisor for Shops
  """

  use Supervisor

  alias Game.Shop
  alias Game.Zone

  def start_link(zone) do
    Supervisor.start_link(__MODULE__, zone, id: zone.id)
  end

  @doc """
  Return all shops that are currently online
  """
  @spec shops(pid :: pid) :: [pid]
  def shops(pid) do
    pid
    |> Supervisor.which_children()
    |> Enum.map(&(elem(&1, 1)))
  end

  @doc """
  Start a newly created shop in the zone
  """
  @spec start_child(pid, shop :: Shop.t) :: :ok
  def start_child(pid, shop) do
    child_spec = worker(Shop, [shop], id: shop.id, restart: :permanent)
    Supervisor.start_child(pid, child_spec)
  end

  def init(zone) do
    children = zone
    |> Shop.for_zone()
    |> Enum.map(fn (shop) ->
      worker(Shop, [shop], id: shop.id, restart: :transient)
    end)

    Zone.shop_supervisor(zone.id, self())

    supervise(children, strategy: :one_for_one)
  end
end
