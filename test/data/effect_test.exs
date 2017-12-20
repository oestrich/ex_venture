defmodule Data.EffectTest do
  use ExUnit.Case
  doctest Data.Effect

  alias Data.Effect

  test "instantiate an effect" do
    effect = %{kind: "damage/over-time", type: :slashing, amount: 2, every: 10, count: 3}
    effect = Effect.instantiate(effect)
    assert effect.id
  end
end
