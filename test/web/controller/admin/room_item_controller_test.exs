defmodule Web.Controller.RoomItemControllerTest do
  use Web.AuthConnCase
  import Test.ItemsHelper

  setup do
    zone = create_zone()
    room = create_room(zone)
    item = create_item()

    start_and_clear_items()
    insert_item(item)

    %{item: item, room: room}
  end

  test "add an item to a room", %{conn: conn, room: room, item: item} do
    conn = post conn, room_room_item_path(conn, :create, room.id, spawn: false), item: %{id: item.id}
    assert html_response(conn, 302)
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
