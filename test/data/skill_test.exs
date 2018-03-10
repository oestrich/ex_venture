defmodule Data.SkillTest do
  use ExUnit.Case

  alias Data.Skill

  describe "validates item effects" do
    test "required" do
      changeset = %Skill{} |> Skill.changeset(%{})
      assert changeset.errors[:effects]
    end

    test "can be an empty array" do
      changeset = %Skill{} |> Skill.changeset(%{effects: []})
      refute changeset.errors[:effects]
    end

    test "valid if all effects are valid" do
      changeset = %Skill{} |> Skill.changeset(%{effects: [%{kind: "damage", amount: 10, type: :slashing}]})
      refute changeset.errors[:effects]
    end

    test "invalid if any are invalid" do
      changeset = %Skill{} |> Skill.changeset(%{effects: [%{kind: "damage", amount: 10, type: :slashing}, %{kind: :damage}]})
      assert changeset.errors[:effects]
    end
  end

  describe "validates white list effects" do
    test "real types are valid" do
      changeset = %Skill{} |> Skill.changeset(%{whitelist_effects: ["damage"]})
      refute changeset.errors[:whitelist_effects]
    end

    test "unknown types are invalid" do
      changeset = %Skill{} |> Skill.changeset(%{whitelist_effects: ["unknown"]})
      assert changeset.errors[:whitelist_effects]
    end
  end
end
