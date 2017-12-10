defmodule Game.ItemTest do
  use ExUnit.Case
  import Test.ItemsHelper
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
end
