defmodule Web.Admin.ZoneControllerTest do
  use Web.AuthConnCase

  test "create a zone", %{conn: conn} do
    zone = %{
      name: "The Forest",
    }

    conn = post conn, zone_path(conn, :create), zone: zone
    assert html_response(conn, 302)
  end
end
