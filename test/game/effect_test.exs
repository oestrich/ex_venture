defmodule Game.EffectTest do
  use Data.ModelCase
  doctest Game.Effect

  import Test.DamageTypesHelper

  alias Game.Effect

  setup do
    start_and_clear_damage_types()

    insert_damage_type(%{
      key: "arcane",
      stat_modifier: :intelligence,
      boost_ratio: 20,
      reverse_stat: :awareness,
      reverse_boost: 20,
    })

    insert_damage_type(%{
      key: "slashing",
      stat_modifier: :strength,
      boost_ratio: 20,
      reverse_stat: :agility,
      reverse_boost: 20,
    })

    insert_damage_type(%{
      key: "bludgeoning",
      stat_modifier: :strength,
      boost_ratio: 20,
      reverse_stat: :vitality,
      reverse_boost: 20,
    })

    :ok
  end

  test "filters out stats effects first and processes those" do
    stat_effect = %{kind: "stats", field: :strength, amount: 10, mode: "add"}
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

  describe "calculating damage" do
    test "simple damage" do
      slashing_effect = %{kind: "damage", type: "slashing", amount: 10}

      calculated_effect = Effect.calculate_damage(slashing_effect, %{strength: -10})
      assert calculated_effect == %{kind: "damage", amount: 5, type: "slashing"}
    end

    test "stat is reduced enough to hit minimum damage" do
      slashing_effect = %{kind: "damage", type: "slashing", amount: 10}

      calculated_effect = Effect.calculate_damage(slashing_effect, %{strength: -30})
      assert calculated_effect == %{kind: "damage", amount: 0, type: "slashing"}
    end
  end

  describe "calculating stats" do
    test "normal stats" do
      stats = %{strength: 10}
      effects = [%{kind: "stats", field: :strength, amount: 10, mode: "add"}, %{kind: "damage"}]

      {stats, effects} = Effect.calculate_stats(stats, effects)

      assert stats == %{strength: 20}
      assert effects == [%{kind: "damage"}]
    end
  end

  describe "calculating stats from continuous effects" do
    test "stats boost" do
      stats = %{strength: 10}

      state = %{
        continuous_effects: [
          {{:user, %{id: 10}}, %{kind: "stats/boost", field: :strength, mode: "add", amount: 10, duration: 1000}},
        ]
      }

      stats = Effect.calculate_stats_from_continuous_effects(stats, state)

      assert stats == %{strength: 20}
    end
  end

  describe "calculating damage effects" do
    test "strength boosts" do
      effect = %{kind: "damage", amount: 10, type: "slashing"}
      effect =  Effect.calculate_damage(effect, %{strength: 10})
      assert effect == %{kind: "damage", amount: 15, type: "slashing"}
    end

    test "intelligence boosts" do
      effect = %{kind: "damage", amount: 10, type: "arcane"}
      effect =  Effect.calculate_damage(effect, %{intelligence: 10})
      assert effect == %{kind: "damage", amount: 15, type: "arcane"}
    end
  end

  describe "adjusting effects before applying - damage" do
    setup do
      %{stats: base_stats()}
    end

    test "damage", %{stats: stats} do
      effects = [%{kind: "damage", type: "slashing", amount: 15}]
      [effect] = Effect.adjust_effects(effects, stats)
      assert effect.amount == 10
    end

    test "strength based", %{stats: stats} do
      effects = [%{kind: "damage/over-time", type: "slashing", amount: 15}]
      [effect] = Effect.adjust_effects(effects, stats)
      assert effect.amount == 10
    end
  end

  describe "applying effects - recovery" do
    test "recover health points" do
      effect = %{kind: "recover", type: "health", amount: 10}
      stats = Effect.apply_effect(effect, %{health_points: 25, max_health_points: 30})
      assert stats == %{health_points: 30, max_health_points: 30}
    end

    test "recover skill points" do
      effect = %{kind: "recover", type: "skill", amount: 10}
      stats = Effect.apply_effect(effect, %{skill_points: 25, max_skill_points: 30})
      assert stats == %{skill_points: 30, max_skill_points: 30}
    end

    test "recover endurance points" do
      effect = %{kind: "recover", type: "endurance", amount: 10}
      stats = Effect.apply_effect(effect, %{endurance_points: 25, max_endurance_points: 30})
      assert stats == %{endurance_points: 30, max_endurance_points: 30}
    end
  end

  describe "processing stats" do
    setup do
      %{stats: %{strength: 10}}
    end

    test "addition", %{stats: stats} do
      effect = %{field: :strength, mode: "add", amount: 10}

      assert Effect.process_stats(effect, stats) == %{strength: 20}
    end

    test "subtraction", %{stats: stats} do
      effect = %{field: :strength, mode: "subtract", amount: 1}

      assert Effect.process_stats(effect, stats) == %{strength: 9}
    end

    test "multiplication", %{stats: stats} do
      effect = %{field: :strength, mode: "multiply", amount: 3}

      assert Effect.process_stats(effect, stats) == %{strength: 30}
    end

    test "division", %{stats: stats} do
      effect = %{field: :strength, mode: "division", amount: 3}

      assert Effect.process_stats(effect, stats) == %{strength: 3}
    end
  end
end
