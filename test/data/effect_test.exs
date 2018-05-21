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
      stats_boost = %{
        "kind" => "stats/boost",
        "field" => "dexterity",
        "amount" => 10,
        "mode" => "add",
        "duration" => 1000
      }

      {:ok, stat_boost} = Effect.load(stats_boost)

      assert stat_boost == %{
        kind: "stats/boost",
        field: :dexterity,
        amount: 10,
        mode: "add",
        duration: 1000
      }
    end

    test "validate them" do
      stat_boost = %{
        kind: "stats/boost",
        field: :dexterity,
        amount: 10,
        mode: "add",
        duration: 1000
      }

      assert Effect.valid?(stat_boost)
    end

    test "validate the mode" do
      stat_boost = %{
        kind: "stats/boost",
        field: :dexterity,
        amount: 10,
        mode: "add",
        duration: 1000
      }

      assert Effect.valid_stats_boost?(stat_boost)

      assert Effect.valid_stats_boost?(%{stat_boost | mode: "subtract"})
      assert Effect.valid_stats_boost?(%{stat_boost | mode: "multiply"})
      assert Effect.valid_stats_boost?(%{stat_boost | mode: "divide"})

      refute Effect.valid_stats_boost?(%{stat_boost | mode: "remove"})
    end
  end
end
