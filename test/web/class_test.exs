defmodule Web.ClassTest do
  use Data.ModelCase

  alias Web.Class

  test "creating a class" do
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

    {:ok, class} = Class.create(params)

    assert class.name == "Fighter"
    assert class.starting_stats.health == 25
  end

  test "updating a class" do
    class = create_class(%{name: "Fighter"})

    {:ok, class} = Class.update(class.id, %{name: "Barbarian"})

    assert class.name == "Barbarian"
  end
end
