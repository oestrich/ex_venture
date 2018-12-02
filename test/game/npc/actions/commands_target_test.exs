defmodule Game.NPC.Actions.CommandsTargetTest do
  use Data.ModelCase

  alias Data.Events.Actions
  alias Game.Character
  alias Game.NPC.State
  alias Game.NPC.Actions.CommandsTarget

  doctest CommandsTarget

  setup do
    %{state: %State{npc: npc_attributes(%{id: 1}), room_id: 1}}
  end

  describe "acting" do
    test "targets the player", %{state: state} do
      action = %Actions.CommandsTarget{}
      player = %Character.Simple{id: 1}

      {:ok, state} = CommandsTarget.act(state, action, {:player, player})

      assert state.combat
      assert state.target
    end

    test "already in combat", %{state: state} do
      state = %{state | combat: true}

      action = %Actions.CommandsTarget{}
      player = %Character.Simple{id: 1}

      {:ok, state} = CommandsTarget.act(state, action, {:player, player})

      assert state.combat
      refute state.target
    end

    test "already has a target", %{state: state} do
      action = %Actions.CommandsTarget{}
      player = %Character.Simple{id: 1}

      state = %{state | target: {:player, player}}

      {:ok, state} = CommandsTarget.act(state, action, {:player, player})

      refute state.combat
      assert state.target
    end
  end
end
