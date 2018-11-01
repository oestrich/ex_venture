defmodule Web.Admin.UserControllerTest do
  use Web.AuthConnCase

  alias Game.Session

  test "teleport a yourself", %{conn: conn, character: character} do
    Session.Registry.register(character)

    zone = create_zone()
    room = create_room(zone)

    conn = post conn, character_path(conn, :teleport), room_id: room.id |> Integer.to_string()
    assert html_response(conn, 302)

    room_id = room.id
    assert_receive {:"$gen_cast", {:teleport, ^room_id}}
  end
end
