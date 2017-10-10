defmodule Data.ItemTagTest do
  use ExUnit.Case

  alias Data.ItemTag

  test "validate type" do
    changeset = %ItemTag{} |> ItemTag.changeset(%{})
    assert changeset.errors[:type]

    changeset = %ItemTag{} |> ItemTag.changeset(%{type: "not-found"})
    assert changeset.errors[:type]
  end

  test "validates item stats" do
    changeset = %ItemTag{} |> ItemTag.changeset(%{})
    assert changeset.errors[:stats]

    changeset = %ItemTag{} |> ItemTag.changeset(%{type: "armor", stats: %{}})
    assert changeset.errors[:stats]

    changeset = %ItemTag{} |> ItemTag.changeset(%{type: "armor", stats: %{slot: :chest, armor: 10}})
    refute changeset.errors[:stats]
  end

  describe "validates item effects" do
    test "required" do
      changeset = %ItemTag{} |> ItemTag.changeset(%{})
      assert changeset.errors[:effects]
    end

    test "can be an empty array" do
      changeset = %ItemTag{} |> ItemTag.changeset(%{type: "armor", effects: []})
      refute changeset.errors[:effects]
    end

    test "valid if all effects are valid" do
      changeset = %ItemTag{} |> ItemTag.changeset(%{type: "weapon", effects: [%{kind: "damage", amount: 10, type: :slashing}]})
      refute changeset.errors[:effects]
    end

    test "invalid if any are invalid" do
      changeset = %ItemTag{} |> ItemTag.changeset(%{type: "armor", effects: [%{kind: "damage", amount: 10, type: :slashing}, %{kind: :damage}]})
      assert changeset.errors[:effects]
    end

    test "must be a damage/stats type for weapons" do
      changeset = %ItemTag{} |> ItemTag.changeset(%{type: "weapon", effects: [%{kind: "damage", amount: 10, type: :slashing}]})
      refute changeset.errors[:effects]

      changeset = %ItemTag{} |> ItemTag.changeset(%{type: "weapon", effects: [%{kind: "stats", field: :strength, amount: 10}]})
      refute changeset.errors[:effects]

      changeset = %ItemTag{} |> ItemTag.changeset(%{type: "weapon", effects: [%{kind: "damage/type", types: [:slashing]}]})
      assert changeset.errors[:effects]
    end

    test "must be a stats type for armor" do
      changeset = %ItemTag{} |> ItemTag.changeset(%{type: "armor", effects: [%{kind: "stats", field: :strength, amount: 10}]})
      refute changeset.errors[:effects]

      changeset = %ItemTag{} |> ItemTag.changeset(%{type: "armor", effects: [%{kind: "damage", amount: 10, type: :slashing}]})
      assert changeset.errors[:effects]

      changeset = %ItemTag{} |> ItemTag.changeset(%{type: "armor", effects: [%{kind: "damage/type", types: [:slashing]}]})
      assert changeset.errors[:effects]
    end
  end
end
