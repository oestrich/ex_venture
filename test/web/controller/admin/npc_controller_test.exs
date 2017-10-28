defmodule Web.Admin.NPCControllerTest do
  use Web.AuthConnCase

  test "new npc", %{conn: conn} do
    params = %{
      "name" => "Bandit",
      "hostile" => "false",
      "level" => "1",
      "experience_points" => "124",
      "currency" => "10",
      "events" => "[]",
      "stats" => base_stats() |> Poison.encode!(),
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
