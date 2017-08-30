defmodule Web.Admin.ClassControllerTest do
  use Web.AuthConnCase

  test "create a class", %{conn: conn} do
    params = %{
      "name" => "Fighter",
      "description" => "A fighter",
      "points_name" => "Skill Points",
      "points_abbreviation" => "SP",
      "regen_health" => 1,
      "regen_skill_points" => 1,
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

    conn = post conn, class_path(conn, :create), class: params
    assert html_response(conn, 302)
  end

  test "update a class", %{conn: conn} do
    class = create_class(%{name: "The Forest"})

    conn = put conn, class_path(conn, :update, class.id), class: %{name: "Barbarian"}
    assert html_response(conn, 302)
  end
end
