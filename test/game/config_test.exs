defmodule Game.ConfigTest do
  use Data.ModelCase

  alias Game.Config

  describe "regen health" do
    test "finding the config value" do
      create_config("regen_health", "10")
      assert Config.regen_health(:default) == 10
    end

    test "using the default" do
      assert Config.regen_health(:default) == :default
    end
  end

  describe "regen skill_points" do
    test "finding the config value" do
      create_config("regen_skill_points", "10")
      assert Config.regen_skill_points(:default) == 10
    end

    test "using the default" do
      assert Config.regen_skill_points(:default) == :default
    end
  end
end
