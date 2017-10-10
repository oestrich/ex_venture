defmodule Data.ItemTest do
  use ExUnit.Case

  alias Data.Item

  test "validate type" do
    changeset = %Item{} |> Item.changeset(%{})
    assert changeset.errors[:type]

    changeset = %Item{} |> Item.changeset(%{type: "not-found"})
    assert changeset.errors[:type]
  end

  test "validates item stats" do
    changeset = %Item{} |> Item.changeset(%{})
    assert changeset.errors[:stats]

    changeset = %Item{} |> Item.changeset(%{type: "armor", stats: %{}})
    assert changeset.errors[:stats]

    changeset = %Item{} |> Item.changeset(%{type: "armor", stats: %{slot: :chest, armor: 10}})
    refute changeset.errors[:stats]
  end

  describe "validates item effects" do
    test "required" do
      changeset = %Item{} |> Item.changeset(%{})
      assert changeset.errors[:effects]
    end

    test "can be an empty array" do
      changeset = %Item{} |> Item.changeset(%{type: "armor", effects: []})
      refute changeset.errors[:effects]
    end

    test "valid if all effects are valid" do
      changeset = %Item{} |> Item.changeset(%{type: "weapon", effects: [%{kind: "damage", amount: 10, type: :slashing}]})
      refute changeset.errors[:effects]
    end

    test "invalid if any are invalid" do
      changeset = %Item{} |> Item.changeset(%{type: "armor", effects: [%{kind: "damage", amount: 10, type: :slashing}, %{kind: :damage}]})
      assert changeset.errors[:effects]
    end

    test "must be a damage/stats type for weapons" do
      changeset = %Item{} |> Item.changeset(%{type: "weapon", effects: [%{kind: "damage", amount: 10, type: :slashing}]})
      refute changeset.errors[:effects]

      changeset = %Item{} |> Item.changeset(%{type: "weapon", effects: [%{kind: "stats", field: :strength, amount: 10}]})
      refute changeset.errors[:effects]

      changeset = %Item{} |> Item.changeset(%{type: "weapon", effects: [%{kind: "damage/type", types: [:slashing]}]})
      refute changeset.errors[:effects]

      changeset = %Item{} |> Item.changeset(%{type: "weapon", effects: [%{kind: "other"}]})
      assert changeset.errors[:effects]
    end

    test "must be a stats type for armor" do
      changeset = %Item{} |> Item.changeset(%{type: "armor", effects: [%{kind: "stats", field: :strength, amount: 10}]})
      refute changeset.errors[:effects]

      changeset = %Item{} |> Item.changeset(%{type: "armor", effects: [%{kind: "damage", amount: 10, type: :slashing}]})
      assert changeset.errors[:effects]

      changeset = %Item{} |> Item.changeset(%{type: "armor", effects: [%{kind: "damage/type", types: [:slashing]}]})
      assert changeset.errors[:effects]
    end
  end
end
