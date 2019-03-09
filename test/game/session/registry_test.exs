defmodule Game.Session.RegistryTest do
  use Data.ModelCase

  alias Game.Events.PlayerSignedIn
  alias Game.Events.PlayerSignedOut
  alias Game.Session.Registry

  describe "online/offline" do
    test "receive a notification for offline" do
      Registry.register(base_character(base_user()))
      Registry.catch_up()

      player = %{base_character(base_user()) | id: 2, name: "Player 2"}
      Registry.player_offline(player)

      assert_receive {:"$gen_cast", {:notify, %PlayerSignedOut{character: %{name: "Player 2"}}}}
    after
      Registry.unregister()
    end

    test "receive a notification for online" do
      Registry.register(base_character(base_user()))
      Registry.catch_up()

      player = %{base_character(base_user()) | id: 2, name: "Player 2"}
      Registry.player_online(player)

      assert_receive {:"$gen_cast", {:notify, %PlayerSignedIn{character: %{name: "Player 2"}}}}
    after
      Registry.unregister()
    end
  end
end
