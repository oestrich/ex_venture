defmodule Web.Controller.RoomItemControllerTest do
  use Web.AuthConnCase

  setup do
    zone = create_zone()
    room = create_room(zone)
    item = create_item()
    room_item = create_room_item(room, item, %{spawn_interval: 15})

    %{room_item: room_item}
  end

  test "delete a room item", %{conn: conn, room_item: room_item} do
    conn = delete conn, room_item_path(conn, :delete, room_item.id)
    assert html_response(conn, 302)
  end
end
