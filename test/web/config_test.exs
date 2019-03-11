defmodule Web.ConfigTest do
  use Data.ModelCase

  alias Web.Config

  test "updating config updates it in the game state" do
    create_config("game_name", "Test MUD")

    {:ok, config} = Config.update("game_name", "Testing MUD")

    assert config.value == "Testing MUD"
  end
end
