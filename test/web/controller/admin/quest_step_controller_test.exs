defmodule Web.Admin.QuestStepControllerTest do
  use Web.AuthConnCase

  test "create a quest step", %{conn: conn} do
    npc = create_npc(%{is_quest_giver: true})
    quest = create_quest(npc, %{name: "Finding a Guard"})

    params = %{
      "type" => "npc/kill",
      "count" => 1,
      "npc_id" => npc.id,
    }

    conn = post conn, quest_step_path(conn, :create, quest.id), quest_step: params
    assert html_response(conn, 302)
  end

  test "update a quest step", %{conn: conn} do
    npc = create_npc(%{is_quest_giver: true})
    quest = create_quest(npc, %{name: "Finding a Guard"})
    step = create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: npc.id})

    conn = put conn, quest_step_path(conn, :update, step.id), quest_step: %{count: 4}
    assert html_response(conn, 302)
  end

  test "delete a quest step", %{conn: conn} do
    npc = create_npc(%{is_quest_giver: true})
    quest = create_quest(npc, %{name: "Finding a Guard"})
    step = create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: npc.id})

    conn = delete conn, quest_step_path(conn, :delete, step.id)
    assert html_response(conn, 302)
  end
end
