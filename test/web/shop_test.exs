defmodule Web.ShopTest do
  use Data.ModelCase

  alias Web.Room
  alias Web.Shop
  alias Web.Zone

  setup do
    {:ok, zone} = Zone.create(%{name: "The Forest"})
    {:ok, room} = Room.create(zone, room_attributes(%{name: "Forest Path"}))
    %{zone: zone, room: room}
  end

  test "creating a new shop pushes it into the room", %{room: room} do
    params = %{name: "Tree Stand Shop"}

    {:ok, shop} = Shop.create(room, params)
    assert shop.name == "Tree Stand Shop"

    state = Game.Room._get_state(room.id)
    assert state.room.shops |> length() == 1
  end

  test "updating a shop updates the room", %{room: room} do
    {:ok, shop} = Shop.create(room, %{name: "Tree Stand Shop"})

    {:ok, shop} = Shop.update(shop.id, %{name: "Tree Stand"})
    assert shop.name == "Tree Stand"

    state = Game.Room._get_state(room.id)
    assert state.room.shops |> List.first() |> Map.get(:name) == "Tree Stand"
  end

  test "adding an item to a shop", %{room: room} do
    item = create_item()
    {:ok, shop} = Shop.create(room, %{name: "Tree Stand Shop"})

    {:ok, shop} = Shop.add_item(shop, item, %{"price" => 100, "quantity" => -1})

    assert shop.shop_items |> length() == 1

    state = Game.Room._get_state(room.id)
    shop = state.room.shops |> List.first()
    assert shop.shop_items |> length() == 1
  end

  test "removing an item from a shop", %{room: room} do
    item = create_item()
    {:ok, shop} = Shop.create(room, %{name: "Tree Stand Shop"})
    {:ok, shop} = Shop.add_item(shop, item, %{"price" => 100, "quantity" => -1})
    shop_item = shop.shop_items |> List.first()

    {:ok, _shop_item} = Shop.delete_item(shop_item.id)

    state = Game.Room._get_state(room.id)
    shop = state.room.shops |> List.first()
    assert shop.shop_items |> length() == 0
  end
end
