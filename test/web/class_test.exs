defmodule Web.ClassTest do
  use Data.ModelCase

  alias Data.ClassProficiency
  alias Data.ClassSkill
  alias Web.Class

  test "creating a class" do
    params = %{
      "name" => "Fighter",
      "description" => "A fighter",
    }

    {:ok, class} = Class.create(params)

    assert class.name == "Fighter"
  end

  test "updating a class" do
    class = create_class(%{name: "Fighter"})

    {:ok, class} = Class.update(class.id, %{name: "Barbarian"})

    assert class.name == "Barbarian"
  end

  describe "class skills" do
    setup do
      %{class: create_class(), skill: create_skill()}
    end

    test "adding skills to a class", %{class: class, skill: skill} do
      assert {:ok, %ClassSkill{}} = Class.add_skill(class, skill.id)
    end

    test "delete a skill from a class", %{class: class, skill: skill} do
      {:ok, class_skill} = Class.add_skill(class, skill.id)

      assert {:ok, _} = Class.remove_skill(class_skill.id)
    end
  end

  describe "class proficiencies" do
    setup do
      %{class: create_class(), proficiency: create_proficiency()}
    end

    test "adding proficiencies to a class", %{class: class, proficiency: proficiency} do
      assert {:ok, %ClassProficiency{}} = Class.add_proficiency(class, %{proficiency_id: proficiency.id, level: 1, points: 10})
    end

    test "delete a proficiency from a class", %{class: class, proficiency: proficiency} do
      {:ok, class_proficiency} = Class.add_proficiency(class, %{proficiency_id: proficiency.id, level: 1, points: 10})

      assert {:ok, _} = Class.remove_proficiency(class_proficiency.id)
    end
  end
end
