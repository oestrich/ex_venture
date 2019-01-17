defmodule ExVenture.NPCCase do
  defmacro __using__(_) do
    quote do
      use Data.ModelCase

      import Test.Game.Room.Helpers

      alias Game.NPC.State
    end
  end
end
