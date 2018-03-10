defmodule Game.ItemTest do
  use Data.ModelCase
  doctest Game.Item

  alias Game.Item

  describe "loading effects" do
    test "load item effects from a player's save" do
      start_and_clear_items()
      insert_item(%{id: 1, effects: [%{kind: "damage"}]})

      assert Item.effects_from_wearing(%{wearing: %{chest: 1}}) == [%{kind: "damage"}]
    end

    test "limit which effects are returned - wearing" do
      start_and_clear_items()
      insert_item(%{id: 1, effects: [%{kind: "damage"}, %{kind: "stats"}]})

      assert Item.effects_from_wearing(%{wearing: %{chest: 1}}, only: ["stats"]) == [%{kind: "stats"}]
    end

    test "limit which effects are returned - wielding" do
      start_and_clear_items()
      insert_item(%{id: 1, effects: [%{kind: "damage"}, %{kind: "stats"}]})

      assert Item.effects_from_wielding(%{wielding: %{left: 1}}, only: ["stats"]) == [%{kind: "stats"}]
    end

    test "load item effects from a player's save - empty" do
      assert Item.effects_from_wearing(%{}) == []
      assert Item.effects_from_wielding(%{}) == []
    end
  end

  describe "fetching all items on a user" do
    test "pulls from items, wielding, and wearing" do
      save = %{
        items: [item_instance(1)],
        wearing: %{chest: item_instance(2)},
        wielding: %{right: item_instance(3)},
      }

      assert [%{id: 1}, %{id: 2}, %{id: 3}] = Item.all_items(save)
    end
  end

  test "filtering out effects that don't match" do
    skill = %Data.Item{whitelist_effects: ["damage"]}
    effects = [
      %{kind: "damage"},
      %{kind: "damage/over-time"},
    ]

    assert Item.filter_effects(effects, skill) == [%{kind: "damage"}]
  end
end
