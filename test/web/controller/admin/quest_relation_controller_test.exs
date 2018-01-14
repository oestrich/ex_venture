defmodule Web.Admin.QuestRelationControllerTest do
  use Web.AuthConnCase

  test "create a quest relation", %{conn: conn} do
    npc = create_npc()
    quest1 = create_quest(npc, %{name: "Finding a Guard 1"})
    quest2 = create_quest(npc, %{name: "Finding a Guard 2"})

    params = %{
      "child_id" => quest2.id,
    }

    conn = post conn, quest_relation_path(conn, :create, quest1.id), side: "parent", quest_relation: params
    assert html_response(conn, 302)
  end
end
