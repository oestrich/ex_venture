defmodule Web.Shop do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Repo
  alias Data.Room
  alias Data.Shop
  alias Data.ShopItem

  alias Game.Room.Repo, as: RoomRepo

  @doc """
  Get a shop
  """
  @spec get(id :: integer) :: [Room.t]
  def get(id) do
    Shop
    |> where([s], s.id == ^id)
    |> preload([shop_items: [:item]])
    |> Repo.one
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new(room :: Room.t) :: changeset :: map
  def new(room) do
    room
    |> Ecto.build_assoc(:shops)
    |> Shop.changeset(%{})
  end

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(shop :: Shop.t) :: changeset :: map
  def edit(shop) do
    shop
    |> Shop.changeset(%{})
  end

  @doc """
  Create a shop
  """
  @spec create(room :: Room.t, params :: map) :: {:ok, Shop.t} | {:error, changeset :: map}
  def create(room, params) do
    changeset = room |> Ecto.build_assoc(:shops) |> Shop.changeset(params)
    case changeset |> Repo.insert() do
      {:ok, shop} ->
        room = RoomRepo.get(shop.room_id)
        Game.Room.update(room.id, room)
        Game.Zone.spawn_shop(room.zone_id, shop)
        {:ok, shop}
      anything -> anything
    end
  end

  @doc """
  Update a shop
  """
  @spec update(id :: integer, params :: map) :: {:ok, Shop.t} | {:error, changeset :: map}
  def update(id, params) do
    changeset = id |> get() |> Shop.changeset(params)
    case changeset |> Repo.update() do
      {:ok, shop} ->
        push_update(shop)
        {:ok, shop}
      anything -> anything
    end
  end

  #
  # Shop Items
  #

  @doc """
  Get a changeset for a new room new
  """
  @spec new_item(shop :: Shop.t) :: changeset :: map
  def new_item(shop) do
    shop
    |> Ecto.build_assoc(:shop_items)
    |> ShopItem.changeset(%{})
  end

  @doc """
  Add an item to a shop
  """
  @spec add_item(shop :: Shop.t, item :: Item.t, params :: map) :: {:ok, Shop.t}
  def add_item(shop, item, params) do
    changeset = shop
    |> Ecto.build_assoc(:shop_items)
    |> ShopItem.changeset(Map.merge(params, %{"item_id" => item.id}))

    case changeset |> Repo.insert() do
      {:ok, _shop_item} ->
        shop = shop.id |> get()
        push_update(shop)
        {:ok, shop}
      anything -> anything
    end
  end

  @doc """
  Delete an item from a shop
  """
  @spec delete_item(shop_item_id :: integer) :: {:ok, ShopItem.t}
  def delete_item(shop_item_id) do
    shop_item = ShopItem |> Repo.get(shop_item_id)
    case shop_item |> Repo.delete() do
      {:ok, shop_item} ->
        shop = shop_item.shop_id |> get()
        push_update(shop)
        {:ok, shop_item}
      anything -> anything
    end
  end

  defp push_update(shop) do
    room = RoomRepo.get(shop.room_id)
    Game.Room.update(room.id, room)
    Game.Shop.update(shop.id, shop)
  end
end
