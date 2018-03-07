defmodule Game.Command.AFKTest do
  use Data.ModelCase
  doctest Game.Command.AFK

  alias Game.Command.AFK

  describe "go afk" do
    setup do
      %{state: %{is_afk: false, socket: :socket}}
    end

    test "toggles it", %{state: state} do
      {:update, state} = AFK.run({:toggle}, state)
      assert state.is_afk

      {:update, state} = AFK.run({:toggle}, state)
      refute state.is_afk
    end
  end
end
