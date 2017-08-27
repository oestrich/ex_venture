defmodule Game.ConfigTest do
  use Data.ModelCase

  alias Game.Config

  describe "regen tick count" do
    test "finding the config value" do
      create_config("regen_tick_count", "10")
      assert Config.regen_tick_count(:default) == 10
    end

    test "using the default" do
      assert Config.regen_tick_count(:default) == :default
    end
  end
end
