defmodule Web.Admin.ShopControllerTest do
  use Web.AuthConnCase

  setup do
    zone = create_zone()
    room = create_room(zone)

    %{zone: zone, room: room}
  end

  test "create a shop", %{conn: conn, room: room} do
    params = %{
      name: "Tree Stand Shop",
    }

    conn = post conn, room_shop_path(conn, :create, room.id), shop: params
    assert html_response(conn, 302)
  end

  test "update a shop", %{conn: conn, room: room} do
    shop = create_shop(room, %{name: "Tree Stand Shop"})

    conn = put conn, shop_path(conn, :update, shop.id), shop: %{name: "Tree Stand"}
    assert html_response(conn, 302)
  end
end
