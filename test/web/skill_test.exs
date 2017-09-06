defmodule Web.SkillTest do
  use Data.ModelCase

  alias Web.Skill

  setup do
    %{class: create_class()}
  end

  test "creating a skill", %{class: class} do
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

    {:ok, skill} = Skill.create(class, params)

    assert skill.name == "Slash"
    assert skill.class_id == class.id
  end

  test "updating a skill", %{class: class} do
    skill = create_skill(class, %{name: "Magic Missile"})

    {:ok, skill} = Skill.update(skill.id, %{name: "Dodge"})
    assert skill.name == "Dodge"
  end
end
