defmodule Game.EffectTest do
  use ExUnit.Case
  doctest Game.Effect

  import Test.DamageTypesHelper

  alias Game.Effect

  setup do
    start_and_clear_damage_types()

    %{key: "arcane", stat_modifier: :intelligence, boost_ratio: 20}
    |> insert_damage_type()

    %{key: "slashing", stat_modifier: :strength, boost_ratio: 20}
    |> insert_damage_type()

    %{key: "bludgeoning", stat_modifier: :strength, boost_ratio: 20}
    |> insert_damage_type()

    :ok
  end

  test "filters out stats effects first and processes those" do
    stat_effect = %{kind: "stats", field: :strength, amount: 10}
    damage_effect = %{kind: "damage", type: "slashing", amount: 10}

    calculated_effects = Effect.calculate(%{strength: 10}, [damage_effect, stat_effect])
    assert calculated_effects == [%{kind: "damage", amount: 20, type: "slashing"}]
  end

  test "changes damage for the damage/type effect" do
    slashing_effect = %{kind: "damage", type: "slashing", amount: 10}
    bludeonging_effect = %{kind: "damage", type: "bludgeoning", amount: 10}
    damage_type_effect = %{kind: "damage/type", types: ["bludgeoning"]}

    calculated_effects = Effect.calculate(%{strength: 10}, [slashing_effect, bludeonging_effect, damage_type_effect])
    assert calculated_effects == [%{kind: "damage", amount: 8, type: "slashing"}, %{kind: "damage", amount: 15, type: "bludgeoning"}]
  end

  describe "calculating damage effects" do
    test "strength boosts" do
      effect = %{kind: "damage", amount: 10, type: "slashing"}
      effect =  Game.Effect.calculate_damage(effect, %{strength: 10})
      assert effect == %{kind: "damage", amount: 15, type: "slashing"}
    end

    test "intelligence boosts" do
      effect = %{kind: "damage", amount: 10, type: "arcane"}
      effect =  Game.Effect.calculate_damage(effect, %{intelligence: 10})
      assert effect == %{kind: "damage", amount: 15, type: "arcane"}
    end
  end

  describe "applying effects" do
    test "recover health points" do
      effect = %{kind: "recover", type: "health", amount: 10}
      stats = Game.Effect.apply_effect(effect, %{health_points: 25, max_health_points: 30})
      assert stats == %{health_points: 30, max_health_points: 30}
    end

    test "recover skill points" do
      effect = %{kind: "recover", type: "skill", amount: 10}
      stats = Game.Effect.apply_effect(effect, %{skill_points: 25, max_skill_points: 30})
      assert stats == %{skill_points: 30, max_skill_points: 30}
    end

    test "recover move points" do
      effect = %{kind: "recover", type: "move", amount: 10}
      stats = Game.Effect.apply_effect(effect, %{move_points: 25, max_move_points: 30})
      assert stats == %{move_points: 30, max_move_points: 30}
    end
  end
end
