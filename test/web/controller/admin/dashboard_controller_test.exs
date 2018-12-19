defmodule Web.Admin.DashboardControllerTest do
  use Web.ConnCase

  test "hitting the dashboard redirects to session", %{conn: conn} do
    conn = get conn, dashboard_path(conn, :index)
    assert redirected_to(conn) == session_path(conn, :new)
  end

  test "user token and an admin allows in", %{conn: conn} do
    user = create_user(%{name: "user", password: "password", flags: ["admin"]})
    character = create_character(user, %{name: "user"})
    user = %{user | characters: [character]}
    conn = conn |> assign(:current_user, user)

    conn = get conn, dashboard_path(conn, :index)
    assert html_response(conn, 200)
  end

  test "user token and a builder allows in", %{conn: conn} do
    user = create_user(%{name: "user", password: "password", flags: ["builder"]})
    character = create_character(user, %{name: "user"})
    user = %{user | characters: [character]}
    conn = conn |> assign(:current_user, user)

    conn = get conn, dashboard_path(conn, :index)
    assert html_response(conn, 200)
  end

  test "user token and not an admin", %{conn: conn} do
    user = create_user(%{name: "user", password: "password", flags: []})
    character = create_character(user, %{name: "user"})
    user = %{user | characters: [character]}
    conn = conn |> assign(:current_user, user)

    conn = get conn, dashboard_path(conn, :index)
    assert redirected_to(conn) == public_page_path(conn, :index)
  end
end
