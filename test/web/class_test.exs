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
      "each_level_stats" => base_stats() |> Poison.encode!(),
    }

    {:ok, class} = Class.create(params)

    assert class.name == "Fighter"
    assert class.each_level_stats.health == 50
  end

  test "updating a class" do
    class = create_class(%{name: "Fighter"})

    {:ok, class} = Class.update(class.id, %{name: "Barbarian"})

    assert class.name == "Barbarian"
  end
end
