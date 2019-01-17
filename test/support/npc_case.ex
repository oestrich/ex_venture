defmodule ExVenture.NPCCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Data.ModelCase

      import Test.Game.Room.Helpers

      alias Game.NPC.State
    end
  end
end
