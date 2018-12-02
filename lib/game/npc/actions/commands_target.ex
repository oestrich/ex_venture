defmodule Game.NPC.Actions.CommandsTarget do
  @moduledoc """
  Target a character
  """

  alias Game.Character
  alias Game.NPC.Events

  @doc """
  Start combat if not already in combat
  """
  def act(state, _action, character) do
    case in_combat?(state) do
      true ->
        {:ok, state}

      false ->
        start_combat(state, character)
    end
  end

  @doc """
  Check if combat is started already
  """
  def in_combat?(state) do
    state.combat || state.target != nil
  end

  @doc """
  Start combat

  Sends a notification and sets the target and marks combat
  """
  def start_combat(state, character) do
    Character.being_targeted(character, Events.npc(state))

    state =
      state
      |> Map.put(:combat, true)
      |> Map.put(:target, character)

    Events.notify_delayed({"combat/ticked"}, 1500)

    {:ok, state}
  end
end
