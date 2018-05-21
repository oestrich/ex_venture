defmodule Data.EffectTest do
  use ExUnit.Case
  doctest Data.Effect

  alias Data.Effect

  test "instantiate an effect" do
    effect = %{kind: "damage/over-time", type: :slashing, amount: 2, every: 10, count: 3}
    effect = Effect.instantiate(effect)
    assert effect.id
  end

  describe "continious stats" do
    test "load them" do
      {:ok, stat_boost} = Effect.load(%{"kind" => "stats/boost", "field" => "dexterity", "amount" => 10, "duration" => 1000})
      assert stat_boost == %{kind: "stats/boost", field: :dexterity, amount: 10, duration: 1000}
    end

    test "validate them" do
      stat_boost = %{kind: "stats/boost", field: :dexterity, amount: 10, duration: 1000}
      assert Effect.valid?(stat_boost)
    end
  end
end
