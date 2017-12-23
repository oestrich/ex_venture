defmodule Web.Admin.ConfigControllerTest do
  use Web.AuthConnCase

  test "update a config", %{conn: conn} do
    create_config("game_name", "Test MUD")

    conn = put conn, config_path(conn, :update, "game_name"), config: %{value: "Testing MUD"}
    assert html_response(conn, 302)
  end
end
