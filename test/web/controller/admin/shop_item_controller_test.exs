defmodule Web.Controller.ShopItemControllerTest do
  use Web.AuthConnCase

  setup do
    zone = create_zone()
    room = create_room(zone)
    shop = create_shop(room)
    item = create_item()

    %{item: item, shop: shop}
  end

  test "add an item to a shop", %{conn: conn, shop: shop, item: item} do
    conn = post conn, shop_shop_item_path(conn, :create, shop.id), item: %{id: item.id}, shop_item: %{price: 15, quantity: -1}
    assert html_response(conn, 302)
  end

  test "delete a shop item", %{conn: conn, shop: shop, item: item} do
    shop_item = create_shop_item(shop, item, %{price: 15, quantity: 10})

    conn = delete conn, shop_item_path(conn, :delete, shop_item.id)
    assert html_response(conn, 302)
  end
end
