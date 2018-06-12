defmodule Web.Controller.RoomExitControllerTest do
  use Web.AuthConnCase

  setup do
    zone = create_zone()
    room1 = create_room(zone, %{x: 1, y: 1})
    room2 = create_room(zone, %{x: 1, y: 2})

    %{room1: room1, room2: room2}
  end

  test "create a new exit", %{conn: conn, room1: room1, room2: room2} do
    params = %{direction: "north", start_room_id: room1.id, finish_room_id: room2.id}

    conn = post conn, room_exit_path(conn, :create, room1.id, direction: "south"), exit: params

    assert html_response(conn, 302)
  end

  test "delete an exit", %{conn: conn, room1: room1, room2: room2} do
    room_exit = create_exit(%{direction: "north", start_room_id: room1.id, finish_room_id: room2.id})

    conn = delete conn, exit_path(conn, :delete, room_exit.id, room_id: room1.id)

    assert html_response(conn, 302)
  end
end
