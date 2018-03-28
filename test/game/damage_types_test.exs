defmodule Game.DamageTypesTest do
  use Data.ModelCase
  import Test.DamageTypesHelper

  alias Game.DamageTypes

  setup do
    start_and_clear_damage_types()
  end

  describe "encountering a new damage type" do
    test "creates the damage type with the defaults" do
      {:ok, bashing} = DamageTypes.get("bashing")

      assert bashing.key == "bashing"
      assert bashing.stat_modifier == :strength
      assert bashing.boost_ratio == 20
    end
  end
end
