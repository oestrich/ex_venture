defmodule Web.RaceTest do
  use Data.ModelCase

  alias Web.Race

  test "creating a race" do
    params = %{
      "name" => "Human",
      "description" => "A human",
      "starting_stats" => %{
        health: 25,
        max_health: 25,
        strength: 10,
        intelligence: 10,
        dexterity: 10,
        skill_points: 10,
        max_skill_points: 10,
        move_points: 10,
        max_move_points: 10,
      } |> Poison.encode!(),
    }

    {:ok, race} = Race.create(params)

    assert race.name == "Human"
    assert race.starting_stats.health == 25
  end

  test "updating a race" do
    race = create_race(%{name: "Human"})

    {:ok, race} = Race.update(race.id, %{name: "Dwarf"})

    assert race.name == "Dwarf"
  end
end
