defmodule Game.EffectTest do
  use ExUnit.Case
  doctest Game.Effect

  alias Game.Effect

  test "filters out stats effects first and processes those" do
    stat_effect = %{kind: "stats", field: :strength, amount: 10}
    damage_effect = %{kind: "damage", type: :slashing, amount: 10}

    calculated_effects = Effect.calculate(%{strength: 10}, [damage_effect, stat_effect])
    assert calculated_effects == [%{kind: "damage", amount: 20, type: :slashing}]
  end

  test "changes damage for the damage/type effect" do
    slashing_effect = %{kind: "damage", type: :slashing, amount: 10}
    bludeonging_effect = %{kind: "damage", type: :bludgeoning, amount: 10}
    damage_type_effect = %{kind: "damage/type", types: [:bludgeoning]}

    calculated_effects = Effect.calculate(%{strength: 10}, [slashing_effect, bludeonging_effect, damage_type_effect])
    assert calculated_effects == [%{kind: "damage", amount: 8, type: :slashing}, %{kind: "damage", amount: 15, type: :bludgeoning}]
  end
end
