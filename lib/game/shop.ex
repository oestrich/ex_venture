defmodule Game.Shop do
  @moduledoc """
  Server for an Shop
  """

  use GenServer
  use Game.Room

  import Ecto.Query

  alias Data.Repo
  alias Data.Shop
  alias Game.Shop.Action

  defmacro __using__(_opts) do
    quote do
      @shop Application.get_env(:ex_venture, :game)[:shop]
    end
  end

  @doc """
  Starts a new Shop

  Will have a registered name with the return from `Game.Shop.pid/1`.
  """
  def start_link(shop) do
    GenServer.start_link(__MODULE__, shop, name: pid(shop.id))
  end

  @doc """
  Helper for determining an Shops registered process name
  """
  @spec pid(id :: integer()) :: atom
  def pid(id) do
    {:via, Registry, {Game.Shop.Registry, id}}
  end

  @doc """
  Load Shops in the zone
  """
  @spec for_zone(zone :: Zone.t) :: [map]
  def for_zone(zone) do
    Shop
    |> join(:left, [s], r in assoc(s, :room))
    |> where([s, r], r.zone_id == ^zone.id)
    |> preload([:shop_items])
    |> Repo.all
  end

  #
  # Client
  #

  @doc """
  Update a shop's data
  """
  @spec update(id :: integer, shop :: Shop.t) :: :ok
  def update(id, shop) do
    GenServer.cast(pid(id), {:update, shop})
  end

  @doc """
  List out a shop
  """
  def list(id) do
    GenServer.call(pid(id), :list)
  end

  @doc """
  Buy from a shop
  """
  def buy(id, item_id, save) do
    GenServer.call(pid(id), {:buy, item_id, save})
  end

  @doc """
  Sell to a shop
  """
  def sell(name, item_name, save) do
    GenServer.call(pid(name), {:sell, item_name, save})
  end

  @doc """
  For testing purposes, get the server's state
  """
  def _get_state(id) do
    GenServer.call(pid(id), :get_state)
  end

  #
  # Server
  #

  def init(shop) do
    {:ok, %{shop: shop}}
  end

  def handle_call(:list, _from, state) do
    {:reply, state.shop, state}
  end

  def handle_call({:buy, item_id, save}, _from, state = %{shop: shop}) do
    case Action.buy(shop, item_id, save) do
      {:ok, save, item, shop} ->
        {:reply, {:ok, save, item}, %{state | shop: shop}}
      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:sell, item_name, save}, _from, state = %{shop: shop}) do
    case Action.sell(shop, item_name, save) do
      {:ok, save, item, shop} ->
        {:reply, {:ok, save, item}, %{state | shop: shop}}
      error ->
        {:reply, error, state}
    end
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:update, shop}, state) do
    {:noreply, Map.put(state, :shop, shop)}
  end
end
