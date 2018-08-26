defmodule Game.Session.RegistryTest do
  use Data.ModelCase

  alias Game.Session.Registry

  describe "online/offline" do
    test "receive a notification for offline" do
      Registry.register(base_user())

      Registry.player_offline(%{id: 2, name: "Player 2"})

      assert_receive {:"$gen_cast", {:notify, {"player/offline", %{name: "Player 2"}}}}
    after
      Registry.unregister()
    end

    test "receive a notification for online" do
      Registry.register(base_user())

      Registry.player_online(%{id: 2, name: "Player 2"})

      assert_receive {:"$gen_cast", {:notify, {"player/online", %{name: "Player 2"}}}}
    after
      Registry.unregister()
    end
  end
end
