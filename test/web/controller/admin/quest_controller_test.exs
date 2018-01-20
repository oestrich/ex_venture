defmodule Web.Admin.QuestControllerTest do
  use Web.AuthConnCase

  test "create a quest", %{conn: conn} do
    npc = create_npc(%{is_quest_giver: true})

    params = %{
      "name" => "Quest",
      "description" => "A quest",
      "completed_message" => "The quest is done",
      "conversations" => [
        %{"key" => "start", "message" => "Hi", "trigger" => "quest"},
      ] |> Poison.encode!(),
      "level" => 1,
      "experience" => 100,
      "giver_id" => npc.id,
    }

    conn = post conn, quest_path(conn, :create), quest: params
    assert html_response(conn, 302)
  end

  test "update a quest", %{conn: conn} do
    npc = create_npc(%{is_quest_giver: true})
    quest = create_quest(npc, %{name: "Finding a Guard"})

    conn = put conn, quest_path(conn, :update, quest.id), quest: %{name: "Kill a Bandit"}
    assert html_response(conn, 302)
  end
end
