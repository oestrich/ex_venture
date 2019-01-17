defmodule ExVenture.CommandCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Data.ModelCase

      import Test.Networking.Socket.Helpers
      import Test.Game.Room.Helpers
    end
  end
end
