defmodule Game.NPC.Actions.CommandsTarget do
  @moduledoc """
  Target a character
  """

  alias Game.Character
  alias Game.Events.CombatTicked
  alias Game.NPC.Events

  @doc """
  Start combat if not already in combat
  """
  def act(state, action) do
    case in_combat?(state) do
      true ->
        {:ok, state}

      false ->
        start_combat(state, action.options)
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
  def start_combat(state, options) do
    with true <- check_target_allowed(options) do
      npc = Character.to_simple(Events.npc(state))
      Character.being_targeted(options.character, npc)

      state =
        state
        |> Map.put(:combat, true)
        |> Map.put(:target, options.character)

      Events.notify_delayed(%CombatTicked{}, 1500)

      {:ok, state}
    else
      _ ->
        {:ok, state}
    end
  end

  def check_target_allowed(options) do
    case options.character.type do
      "player" ->
        Map.get(options, :player, false)

      "npc" ->
        Map.get(options, :npc, false)
    end
  end
end
