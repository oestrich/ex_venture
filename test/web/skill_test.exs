defmodule Web.SkillTest do
  use Data.ModelCase
  import Test.SkillsHelper

  alias Game.Skills
  alias Web.Skill

  setup do
    start_and_clear_skills()
  end

  test "creating a skill" do
    params = %{
      "name" => "Slash",
      "command" => "slash",
      "description" => "Slash at the target",
      "level" => 1,
      "user_text" => "You slash at your {target}",
      "usee_text" => "You are slashed at by {who}",
      "points" => 3,
      "effects" => "[]",
    }

    {:ok, skill} = Skill.create(params)

    assert skill.name == "Slash"

    assert Skills.skill(skill.id).name == "Slash"
  end

  test "updating a skill" do
    skill = create_skill(%{name: "Magic Missile"})

    {:ok, skill} = Skill.update(skill.id, %{name: "Dodge"})
    assert skill.name == "Dodge"

    assert Skills.skill(skill.id).name == "Dodge"
  end
end
