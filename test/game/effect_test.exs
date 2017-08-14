defmodule Game.EffectTest do
  use ExUnit.Case
  doctest Game.Effect

  test "filters out stats effects first and processes those" do
    stat_effect = %{kind: "stats", field: :strength, amount: 10}
    damage_effect = %{kind: "damage", type: :slashing, amount: 10}

    calculated_effects = Game.Effect.calculate(%{strength: 10}, [damage_effect, stat_effect])
    assert calculated_effects == [%{kind: "damage", amount: 12, type: :slashing}]
  end
end
