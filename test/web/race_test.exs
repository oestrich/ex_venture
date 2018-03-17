defmodule Web.RaceTest do
  use Data.ModelCase

  alias Data.RaceSkill
  alias Web.Race

  test "creating a race" do
    params = %{
      "name" => "Human",
      "description" => "A human",
      "starting_stats" => %{
        health_points: 25,
        max_health_points: 25,
        strength: 10,
        dexterity: 10,
        constitution: 13,
        intelligence: 10,
        wisdom: 10,
        skill_points: 10,
        max_skill_points: 10,
        move_points: 10,
        max_move_points: 10,
      } |> Poison.encode!(),
    }

    {:ok, race} = Race.create(params)

    assert race.name == "Human"
    assert race.starting_stats.health_points == 25
  end

  test "updating a race" do
    race = create_race(%{name: "Human"})

    {:ok, race} = Race.update(race.id, %{name: "Dwarf"})

    assert race.name == "Dwarf"
  end

  describe "race skills" do
    setup do
      %{race: create_race(), skill: create_skill()}
    end

    test "adding skills to a race", %{race: race, skill: skill} do
      assert {:ok, %RaceSkill{}} = Race.add_skill(race, skill.id)
    end

    test "delete a skill from a race", %{race: race, skill: skill} do
      {:ok, race_skill} = Race.add_skill(race, skill.id)

      assert {:ok, _} = Race.remove_skill(race_skill.id)
    end
  end
end
