defmodule Web.ShopTest do
  use Data.ModelCase

  alias Web.Shop

  setup do
    zone = create_zone(%{name: "The Forest"})
    room = create_room(zone, %{name: "Forest Path"})

    %{zone: zone, room: room}
  end

  test "creating a new shop pushes it into the room and spawns a process", %{room: room, zone: zone} do
    NamedProcess.start_link({Game.Zone, zone.id})

    {:ok, shop} = Shop.create(room, %{name: "Tree Stand Shop"})

    assert shop.name == "Tree Stand Shop"
    assert_receive {_, {:cast, {:spawn_shop, _}}}
  end

  test "updating a shop updates the room", %{room: room} do
    shop = create_shop(room, %{name: "Tree Stand Shop"})
    NamedProcess.start_link({Game.Room, room.id})
    NamedProcess.start_link({Game.Shop, shop.id})

    {:ok, shop} = Shop.update(shop.id, %{name: "Tree Stand"})
    assert shop.name == "Tree Stand"

    assert_receive {{Game.Room, _}, {:cast, {:update, _}}}
    assert_receive {{Game.Shop, _}, {:cast, {:update, _}}}
  end

  test "adding an item to a shop", %{room: room} do
    shop = create_shop(room, %{name: "Tree Stand Shop"})
    NamedProcess.start_link({Game.Shop, shop.id})

    item = create_item()

    {:ok, _shop_item} = Shop.add_item(shop, item, %{"price" => 100, "quantity" => -1})

    shop = Shop.get(shop.id)
    assert length(shop.shop_items) == 1

    assert_receive {_, {:cast, {:update, _}}}
  end

  test "updating an item to a shop", %{room: room} do
    shop = create_shop(room, %{name: "Tree Stand Shop"})
    NamedProcess.start_link({Game.Shop, shop.id})

    item = create_item()

    {:ok, shop_item} = Shop.add_item(shop, item, %{"price" => 100, "quantity" => -1})
    {:ok, _shop_item} = Shop.update_item(shop_item.id, %{"price" => 200})

    assert_receive {_, {:cast, {:update, _}}}
  end

  test "removing an item from a shop", %{room: room} do
    item = create_item()
    shop = create_shop(room, %{name: "Tree Stand Shop"})
    NamedProcess.start_link({Game.Shop, shop.id})

    {:ok, shop_item} = Shop.add_item(shop, item, %{"price" => 100, "quantity" => -1})

    {:ok, _shop_item} = Shop.delete_item(shop_item.id)

    assert_receive {_, {:cast, {:update, _}}}
    assert_receive {_, {:cast, {:update, _}}}
  end
end
