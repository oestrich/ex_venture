defmodule Web.Admin.RoomControllerTest do
  use Web.AuthConnCase

  alias Web.Zone

  setup do
    {:ok, zone} = Zone.create(%{name: "The Forest"})
    %{zone: zone}
  end

  test "create a zone", %{conn: conn, zone: zone} do
    room = %{
      name: "Forest Path",
      description: "A small forest path",
    }

    conn = post conn, zone_room_path(conn, :create, zone.id), room: room
    assert html_response(conn, 302)
  end
end
