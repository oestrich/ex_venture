defmodule Data.ItemAspectTest do
  use ExUnit.Case

  alias Data.ItemAspect

  test "validate type" do
    changeset = %ItemAspect{} |> ItemAspect.changeset(%{})
    assert changeset.errors[:type]

    changeset = %ItemAspect{} |> ItemAspect.changeset(%{type: "not-found"})
    assert changeset.errors[:type]
  end

  test "validates item stats" do
    changeset = %ItemAspect{} |> ItemAspect.changeset(%{})
    assert changeset.errors[:stats]

    changeset = %ItemAspect{} |> ItemAspect.changeset(%{type: "armor", stats: %{}})
    assert changeset.errors[:stats]

    changeset = %ItemAspect{} |> ItemAspect.changeset(%{type: "armor", stats: %{slot: :chest, armor: 10}})
    refute changeset.errors[:stats]
  end

  describe "validates item effects" do
    test "required" do
      changeset = %ItemAspect{} |> ItemAspect.changeset(%{})
      assert changeset.errors[:effects]
    end

    test "can be an empty array" do
      changeset = %ItemAspect{} |> ItemAspect.changeset(%{type: "armor", effects: []})
      refute changeset.errors[:effects]
    end

    test "valid if all effects are valid" do
      changeset =
        %ItemAspect{}
        |> ItemAspect.changeset(%{type: "weapon", effects: [%{kind: "damage", amount: 10, type: "slashing"}]})

      refute changeset.errors[:effects]
    end

    test "invalid if any are invalid" do
      changeset =
        %ItemAspect{}
        |> ItemAspect.changeset(%{type: "armor", effects: [%{kind: "damage", amount: 10, type: "slashing"}, %{kind: :damage}]})

      assert changeset.errors[:effects]
    end
  end
end
