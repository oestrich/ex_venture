defmodule Data.ItemTest do
  use Data.ModelCase

  doctest Data.Item.Compiled
  doctest Data.Item.Instance

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

  describe "compiling an item from its tags" do
    test "merges stats together" do
      item_aspect = create_item_aspect(%{type: "armor", stats: %{slot: :chest, armor: 11}})
      item = create_item(%{type: "armor", stats: %{slot: :chest, armor: 10}})
      create_item_aspecting(item, item_aspect)
      item = Repo.preload(item, [item_aspectings: [:item_aspect]])

      compiled_item = Item.compile(item)

      assert %Item.Compiled{} = compiled_item
      assert compiled_item.stats == %{slot: :chest, armor: 21}
    end

    test "stats scale with levels" do
      item_aspect = create_item_aspect(%{type: "armor", stats: %{slot: :chest, armor: 11}})
      item = create_item(%{level: 10, type: "armor", stats: %{slot: :chest, armor: 10}})
      create_item_aspecting(item, item_aspect)
      item = Repo.preload(item, [item_aspectings: [:item_aspect]])

      compiled_item = Item.compile(item)

      assert %Item.Compiled{} = compiled_item
      assert compiled_item.stats == %{slot: :chest, armor: 31}
    end

    test "merges effects together" do
      item_aspect = create_item_aspect(%{effects: [%{kind: "damage/type", types: [:slashing]}]})
      item = create_item(%{effects: [%{kind: "damage", type: :slashing, amount: 30}]})
      create_item_aspecting(item, item_aspect)
      item = Repo.preload(item, [item_aspectings: [:item_aspect]])

      compiled_item = Item.compile(item)

      assert %Item.Compiled{} = compiled_item
      assert compiled_item.effects == [
        %{kind: "damage", type: :slashing, amount: 30},
        %{kind: "damage/type", types: [:slashing]},
      ]
    end

    test "effects scale with levels" do
      item_aspect = create_item_aspect(%{
        effects: [
          %{kind: "damage/type", types: [:slashing]},
          %{kind: "damage", type: :slashing, amount: 10},
        ],
      })

      item = create_item(%{level: 11})
      create_item_aspecting(item, item_aspect)
      item = Repo.preload(item, [item_aspectings: [:item_aspect]])

      compiled_item = Item.compile(item)

      assert %Item.Compiled{} = compiled_item
      assert compiled_item.effects == [
        %{kind: "damage/type", types: [:slashing]},
        %{kind: "damage", type: :slashing, amount: 20},
      ]
    end
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

  test "create an instance of an item" do
    item = create_item()

    instance = Item.instantiate(item)

    assert instance.id == item.id
    assert instance.created_at
  end
end
