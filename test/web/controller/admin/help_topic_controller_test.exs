defmodule Web.Admin.HelpTopicControllerTest do
  use Web.AuthConnCase

  test "create a help topic", %{conn: conn} do
    params = %{
      name: "Fighter",
      keywords: "fighter,class",
      body: "This class uses physical skills",
    }

    conn = post conn, help_topic_path(conn, :create), help_topic: params
    assert html_response(conn, 302)
  end

  test "update a help topic", %{conn: conn} do
    help_topic = create_help_topic(%{
      name: "Fighter",
      keywords: ["fighter", "class"],
      body: "This class uses physical skills",
    })

    conn = put conn, help_topic_path(conn, :update, help_topic.id), help_topic: %{name: "Barbarian"}
    assert html_response(conn, 302)
  end
end
