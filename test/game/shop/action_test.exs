defmodule Game.Shop.ActionTest do
  use Data.ModelCase

  alias Data.Item
  alias Data.Shop
  alias Game.Shop.Action

  describe "buying items" do
    setup do
      shop = %Shop{name: "Tree Top Shop"}
      item = item_attributes(%{id: 1, name: "Sword", keywords: [], cost: 10})
      save = %{base_save() | currency: 100}

      start_and_clear_items()
      insert_item(item)

      shop = %{shop | shop_items: [%{id: 2, item_id: item.id, price: 10, quantity: 10}]}

      %{shop: shop, item: item, save: save}
    end

    test "successfully buy an item", %{shop: shop, item: item, save: save} do
      {:ok, save, ^item, shop} = Action.buy(shop, "sword", save)

      assert save.currency == 90
      assert [%Item.Instance{}] = save.items
      assert [%{quantity: 9}] = shop.shop_items
    end

    test "quantity is unlimited", %{shop: shop, item: item, save: save} do
      shop = %{shop | shop_items: [%{id: 2, item_id: item.id, price: 10, quantity: -1}]}

      {:ok, save, ^item, shop} = Action.buy(shop, "sword", save)

      assert save.currency == 90
      assert [%{quantity: -1}] = shop.shop_items
    end

    test "item not found", %{shop: shop, save: save} do
      save = %{save | currency: 5}

      {:error, :item_not_found} = Action.buy(shop, "swrd", save)
    end

    test "not enough currency in the save", %{shop: shop, item: item, save: save} do
      save = %{save | currency: 5}

      {:error, :not_enough_currency, ^item} = Action.buy(shop, "sword", save)
    end

    test "not enough quantity in the shop", %{shop: shop, item: item, save: save} do
      shop = %{shop | shop_items: [%{id: 2, item_id: item.id, price: 10, quantity: 0}]}

      {:error, :not_enough_quantity, ^item} = Action.buy(shop, "sword", save)
    end
  end

  describe "selling items" do
    setup do
      shop = %Shop{name: "Tree Top Shop"}
      item = item_attributes(%{id: 1, name: "Sword", keywords: [], cost: 10})
      save = %{base_save() | currency: 100, items: [item_instance(1)]}

      start_and_clear_items()
      insert_item(item)

      %{shop: shop, item: item, save: save}
    end

    test "successfully sell an item", %{shop: shop, item: item, save: save} do
      {:ok, save, ^item, ^shop} = Action.sell(shop, "sword", save)

      assert save.currency == 110
      assert save.items == []
    end

    test "item not found", %{shop: shop, save: save} do
      {:error, :item_not_found} = Action.sell(shop, "swrd", save)
    end
  end
end
