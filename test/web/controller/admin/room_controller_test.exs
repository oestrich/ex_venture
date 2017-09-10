defmodule Web.Admin.RoomControllerTest do
  use Web.AuthConnCase

  alias Web.Room
  alias Web.Zone

  setup do
    {:ok, zone} = Zone.create(%{name: "The Forest"})
    %{zone: zone}
  end

  test "create a room", %{conn: conn, zone: zone} do
    room = %{
      name: "Forest Path",
      description: "A small forest path",
      currency: "10",
      x: 1,
      y: 1,
    }

    conn = post conn, zone_room_path(conn, :create, zone.id), room: room
    assert html_response(conn, 302)
  end

  test "update a room", %{conn: conn, zone: zone} do
    params = %{
      name: "Forest Path",
      description: "A small forest path",
      currency: "10",
      x: 1,
      y: 1,
    }
    {:ok, room} = Room.create(zone, params)

    conn = put conn, room_path(conn, :update, room.id), room: %{name: "Forest"}
    assert html_response(conn, 302)
  end
end
