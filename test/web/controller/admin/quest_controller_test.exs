defmodule Web.Admin.QuestControllerTest do
  use Web.AuthConnCase

  test "create a quest", %{conn: conn} do
    npc = create_npc()

    params = %{
      "name" => "Fighter",
      "description" => "A fighter",
      "level" => 1,
      "giver_id" => npc.id,
    }

    conn = post conn, quest_path(conn, :create), quest: params
    assert html_response(conn, 302)
  end

  test "update a quest", %{conn: conn} do
    npc = create_npc()
    quest = create_quest(npc, %{name: "Finding a Guard"})

    conn = put conn, quest_path(conn, :update, quest.id), quest: %{name: "Kill a Bandit"}
    assert html_response(conn, 302)
  end
end
