defmodule Web.Admin.ZoneControllerTest do
  use Web.AuthConnCase

  test "create a zone", %{conn: conn} do
    zone = %{
      name: "The Forest",
      description: "For level 1-4",
    }

    conn = post conn, zone_path(conn, :create), zone: zone
    assert html_response(conn, 302)
  end

  test "update a zone", %{conn: conn} do
    zone = create_zone(zone_attributes(%{name: "The Forest"}))

    conn = put conn, zone_path(conn, :update, zone.id), zone: %{name: "Forest"}
    assert html_response(conn, 302)
  end
end
