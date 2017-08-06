defmodule Web.Admin.DashboardControllerTest do
  use Web.ConnCase

  test "hitting the dashboard redirects to session", %{conn: conn} do
    conn = get conn, dashboard_path(conn, :index)
    assert redirected_to(conn) == session_path(conn, :new)
  end

  test "user token and an admin allows in", %{conn: conn} do
    user = create_user(%{name: "user", password: "password", flags: ["admin"]})
    conn = conn |> assign(:user, user)

    conn = get conn, dashboard_path(conn, :index)
    assert html_response(conn, 200)
  end

  test "user token and not an admin", %{conn: conn} do
    user = create_user(%{name: "user", password: "password", flags: []})
    conn = conn |> assign(:user, user)

    conn = get conn, dashboard_path(conn, :index)
    assert redirected_to(conn) == session_path(conn, :new)
  end
end
