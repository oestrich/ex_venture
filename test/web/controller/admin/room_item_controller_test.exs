defmodule Web.Controller.RoomItemControllerTest do
  use Web.AuthConnCase

  setup do
    zone = create_zone()
    room = create_room(zone)
    item = create_item()

    %{item: item, room: room}
  end

  test "add a room item", %{conn: conn, room: room, item: item} do
    conn = post conn, room_room_item_path(conn, :create, room.id), room_item: %{item_id: item.id, spawn_interval: 15}
    assert html_response(conn, 302)
  end

  test "delete a room item", %{conn: conn, room: room, item: item} do
    room_item = create_room_item(room, item, %{spawn_interval: 15})

    conn = delete conn, room_item_path(conn, :delete, room_item.id)
    assert html_response(conn, 302)
  end
end
