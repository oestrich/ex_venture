defmodule Web.Admin.RaceControllerTest do
  use Web.AuthConnCase

  test "create a race", %{conn: conn} do
    params = %{
      "name" => "Fighter",
      "description" => "A fighter",
      "starting_stats" => %{
        health: 25,
        max_health: 25,
        strength: 10,
        intelligence: 10,
        dexterity: 10,
        skill_points: 10,
        max_skill_points: 10,
      } |> Poison.encode!(),
    }

    conn = post conn, race_path(conn, :create), race: params
    assert html_response(conn, 302)
  end

  test "update a race", %{conn: conn} do
    race = create_race(%{name: "Human"})

    conn = put conn, race_path(conn, :update, race.id), race: %{name: "Dwarf"}
    assert html_response(conn, 302)
  end
end
