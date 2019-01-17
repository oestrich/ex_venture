defmodule ExVenture.SessionCase do
  defmacro __using__(_) do
    quote do
      use Data.ModelCase

      import Test.Game.Room.Helpers
      import Test.Game.Zone.Helpers
      import Test.Networking.Socket.Helpers
    end
  end
end
