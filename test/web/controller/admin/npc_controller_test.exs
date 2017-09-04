defmodule Web.Admin.NPCControllerTest do
  use Web.AuthConnCase

  test "new npc", %{conn: conn} do
    params = %{
      "name" => "Bandit",
      "hostile" => "false",
      "level" => "1",
      "experience_points" => "124",
      "stats" => %{
        health: 25,
        max_health: 25,
        strength: 10,
        intelligence: 10,
        dexterity: 10,
        skill_points: 10,
        max_skill_points: 10,
      } |> Poison.encode!(),
    }

    conn = post conn, npc_path(conn, :create), npc: params
    assert html_response(conn, 302)
  end

  test "update a npc", %{conn: conn} do
    npc = create_npc(%{name: "Bandit"})

    conn = put conn, npc_path(conn, :update, npc.id), npc: %{name: "Barbarian"}
    assert html_response(conn, 302)
  end
end
