defmodule Game.NPC.Actions do
  @moduledoc """
  Handles processing actions for an event, including delaying them
  """

  alias Data.Events
  alias Game.NPC.Actions
  alias Game.Skills

  @doc """
  Delay a batch of actions from an event
  """
  def delay([]), do: :ok

  def delay([action | actions]) do
    Process.send_after(self(), {:delayed_actions, [action | actions]}, calculate_delay(action))
  end

  @doc """
  Process the next action

  Acts on the top action and delays the rest
  """
  def process(state, []), do: {:ok, state}

  def process(state, [action | actions]) do
    case get_module(action).act(state, action) do
      {:ok, state} ->
        delay(actions)

        {:ok, state}

      error ->
        error
    end
  end

  defp get_module(%Events.Actions.CommandsEmote{}), do: Actions.CommandsEmote

  defp get_module(%Events.Actions.CommandsMove{}), do: Actions.CommandsMove

  defp get_module(%Events.Actions.CommandsSay{}), do: Actions.CommandsSay

  defp get_module(%Events.Actions.CommandsSkill{}), do: Actions.CommandsSkill

  defp get_module(%Events.Actions.CommandsTarget{}), do: Actions.CommandsTarget

  @doc """
  Add a character to the options of any action that requires it

  This is the character that prompted the action to be sent to the NPC
  """
  def add_character(actions, character) do
    Enum.map(actions, &maybe_add_character_option(&1, character))
  end

  defp maybe_add_character_option(action = %Events.Actions.CommandsSkill{}, character) do
    options = Map.get(action, :options) || %{}
    options = Map.put(options, :character, unwrap_character(character))
    %{action | options: options}
  end

  defp maybe_add_character_option(action = %Events.Actions.CommandsTarget{}, character) do
    options = Map.get(action, :options) || %{}
    options = Map.put(options, :character, unwrap_character(character))
    %{action | options: options}
  end

  defp maybe_add_character_option(action, _character), do: action

  defp unwrap_character({_, character}), do: character

  defp unwrap_character(character), do: character

  @doc """
  Calculate a delay for an action

      iex> Actions.calculate_delay(%{delay: 0.01})
      10

      iex> Actions.calculate_delay(%{delay: nil})
      0

      iex> Actions.calculate_delay(%{})
      0
  """
  def calculate_delay(action) do
    delay = Map.get(action, :delay, 0) || 0
    round(delay * 1000)
  end

  @doc """
  Calculates the total delay for an action

  Includes any cooldown for skills, etc
  """
  def calculate_total_delay(action = %Events.Actions.CommandsSkill{}) do
    case Skills.skill(Map.get(action.options, :skill)) do
      nil ->
        calculate_delay(action)

      skill ->
        skill.cooldown_time + calculate_delay(action)
    end
  end

  def calculate_total_delay(action) do
    calculate_delay(action)
  end
end
