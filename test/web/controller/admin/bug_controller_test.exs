defmodule Web.Admin.BugControllerTest do
  use Web.AuthConnCase

  test "update a bug", %{conn: conn} do
    user = create_user(%{name: "reporter", password: "password"})
    character = create_character(user, %{name: "reporter"})
    bug = create_bug(character, %{title: "A bug", body: "more details"})

    conn = post conn, bug_complete_path(conn, :complete, bug.id)
    assert html_response(conn, 302)
  end
end
