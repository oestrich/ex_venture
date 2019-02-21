defmodule Game.Session.RegistryTest do
  use Data.ModelCase

  alias Game.Events.PlayerSignedIn
  alias Game.Events.PlayerSignedOut
  alias Game.Session.Registry

  describe "online/offline" do
    test "receive a notification for offline" do
      Registry.register(base_character(base_user()))
      Registry.catch_up()

      Registry.player_offline(%{id: 2, name: "Player 2"})

      assert_receive {:"$gen_cast", {:notify, %PlayerSignedOut{character: {:player, %{name: "Player 2"}}}}}
    after
      Registry.unregister()
    end

    test "receive a notification for online" do
      Registry.register(base_character(base_user()))
      Registry.catch_up()

      Registry.player_online(%{id: 2, name: "Player 2"})

      assert_receive {:"$gen_cast", {:notify, %PlayerSignedIn{character: {:player, %{name: "Player 2"}}}}}
    after
      Registry.unregister()
    end
  end
end
