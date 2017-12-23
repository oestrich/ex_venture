defmodule Web.ConfigTest do
  use Data.ModelCase

  alias Game.Config, as: GameConfig
  alias Web.Config

  test "updating config updates it in the game state" do
    create_config("game_name", "Test MUD")

    assert GameConfig.game_name() == "Test MUD" # Load it into the agent

    {:ok, _config} = Config.update("game_name", "Testing MUD")

    assert GameConfig.game_name() == "Testing MUD"
  end
end
