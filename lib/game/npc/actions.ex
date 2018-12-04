defmodule Game.NPC.Actions do
  @moduledoc """
  Handles processing actions for an event, including delaying them
  """

  alias Data.Events
  alias Game.NPC.Actions

  @doc """
  Delay a batch of actions from an event
  """
  def delay([]), do: :ok

  def delay([action | actions]) do
    Process.send_after(self(), {:delayed_actions, [action | actions]}, calculate_delay(action))
  end

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

  defp get_module(%{__struct__: Events.Actions.CommandsEmote}), do: Actions.CommandsEmote

  defp get_module(%{__struct__: Events.Actions.CommandsMove}), do: Actions.CommandsMove

  defp get_module(%{__struct__: Events.Actions.CommandsSay}), do: Actions.CommandsSay

  defp get_module(%{__struct__: Events.Actions.CommandsSkill}), do: Actions.CommandsSkill

  defp get_module(%{__struct__: Events.Actions.CommandsTarget}), do: Actions.CommandsTarget

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
end
