defmodule Web.Admin.NoteControllerTest do
  use Web.AuthConnCase

  test "create a note", %{conn: conn} do
    params = %{
      "name" => "Gods",
      "body" => "There are some gods here",
      "tags" => "gods,magic",
    }

    conn = post conn, note_path(conn, :create), note: params
    assert html_response(conn, 302)
  end

  test "update a note", %{conn: conn} do
    note = create_note(%{name: "The Forest"})

    conn = put conn, note_path(conn, :update, note.id), note: %{name: "Barbarian"}
    assert html_response(conn, 302)
  end
end
