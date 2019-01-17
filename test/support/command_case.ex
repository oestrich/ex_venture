defmodule ExVenture.CommandCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Data.ModelCase

      import Test.Networking.Socket.Helpers
      import Test.Game.NPC.Helpers
      import Test.Game.Room.Helpers
      import Test.Game.Shop.Helpers
      import Test.Game.Zone.Helpers
    end
  end
end
