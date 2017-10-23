defmodule Game.Shop.Action do
  @moduledoc """
  Shop actions
  """

  alias Game.Item
  alias Game.Items
  alias Game.Shop
  alias Metrics.ShopInstrumenter

  @doc """
  Buy an item from a shop
  """
  def buy(shop, item_name, save) do
    items = Enum.map(shop.shop_items, &(&1.item_id |> Items.item()))
    item = Enum.find(items, &(Item.matches_lookup?(&1, item_name)))

    case item do
      nil -> {:error, :item_not_found}
      item ->
        shop_item = Enum.find(shop.shop_items, &(&1.item_id == item.id))
        buy_item_if_enough(shop, shop_item, item, save)
    end
  end

  def buy_item_if_enough(_shop, %{quantity: 0}, item, _save), do: {:error, :not_enough_quantity, item}
  def buy_item_if_enough(shop, shop_item, item, save), do: maybe_buy_item(shop, shop_item, item, save)

  def change_quantity(shop_item = %{quantity: -1}), do: shop_item
  def change_quantity(shop_item), do: %{shop_item | quantity: shop_item.quantity - 1}

  def maybe_buy_item(shop, shop_item, item, save) do
    case save.currency - shop_item.price do
      currency when currency < 0 -> {:error, :not_enough_currency, item}
      currency ->
        ShopInstrumenter.buy(shop_item.price)
        save = %{save | currency: currency, item_ids: [item.id | save.item_ids]}
        shop_item = change_quantity(shop_item)
        shop_items = [shop_item | shop.shop_items] |> Enum.uniq_by(&(&1.id))
        {:ok, save, item, %{shop | shop_items: shop_items}}
    end
  end

  @doc """
  Sell an item to a shop
  """
  @spec sell(shop :: Shop.t, item_name :: String.t, save :: map) :: {:ok, save :: map, item :: Item.t, shop :: Shop.t}
  def sell(shop, item_name, save) do
    items = Enum.map(save.item_ids, &Items.item/1)
    item = Enum.find(items, &(Item.matches_lookup?(&1, item_name)))

    case item do
      nil -> {:error, :item_not_found}
      item ->
        ShopInstrumenter.buy(item.cost)
        item_ids = List.delete(save.item_ids, item.id)
        currency = save.currency + item.cost
        save = %{save | item_ids: item_ids, currency: currency}
        {:ok, save, item, shop}
    end
  end
end
