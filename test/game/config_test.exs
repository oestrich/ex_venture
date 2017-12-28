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

  describe "motd" do
    test "finding the config value" do
      create_config("motd", "ExVenture")
      assert Config.motd(:default) == "ExVenture"
    end

    test "using the default" do
      assert Config.motd(:default) == :default
    end
  end

  describe "after_sign_in_message" do
    test "finding the config value" do
      create_config("after_sign_in_message", "ExVenture")
      assert Config.after_sign_in_message(:default) == "ExVenture"
    end

    test "using the default" do
      assert Config.after_sign_in_message(:default) == :default
    end
  end

  describe "game name" do
    test "finding the config value" do
      create_config("game_name", "ExVenture")
      assert Config.game_name(:default) == "ExVenture"
    end

    test "using the default" do
      assert Config.game_name(:default) == :default
    end

    test "has a default provided" do
      assert Config.game_name() == "ExVenture"
    end
  end

  describe "starting save" do
    test "finding the config value" do
      create_config("starting_save", %{} |> Poison.encode!())
      assert %Data.Save{items: [], currency: 0} = Config.starting_save()
    end
  end
end
