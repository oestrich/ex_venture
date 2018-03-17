defmodule Web.Admin.ClassControllerTest do
  use Web.AuthConnCase

  test "create a class", %{conn: conn} do
    params = %{
      "name" => "Fighter",
      "description" => "A fighter",
    }

    conn = post conn, class_path(conn, :create), class: params
    assert html_response(conn, 302)
  end

  test "update a class", %{conn: conn} do
    class = create_class(%{name: "The Forest"})

    conn = put conn, class_path(conn, :update, class.id), class: %{name: "Barbarian"}
    assert html_response(conn, 302)
  end
end
