defmodule Game.NPC.Combat do
  @moduledoc """
  Module to hold functions for the `combat/tick`
  """

  alias Data.Event

  @doc """
  Select a weighted event from the list of events
  """
  @spec weighted_event(events :: [Event.t]) :: Event.t
  def weighted_event(events) do
    events
    |> total_weights()
    |> :rand.uniform()
    |> select_action(events)
  end

  @doc """
  Determine the total number of weights in the events. Pre-filter for `combat/tick`s.
  """
  @spec total_weights(events :: [Event.t]) :: integer()
  def total_weights(events) do
    Enum.reduce(events, 0, &(&1.action.weight + &2))
  end

  @doc """
  Select the action based on the total
  """
  @spec select_action(weight :: integer(), events :: [Event.t]) :: Event.t
  def select_action(weight, events, count \\ 0)
  def select_action(_weight, [event], _count), do: event
  def select_action(weight, [event | events], count) do
    case weight <= event.action.weight + count do
      true -> event
      false -> select_action(weight, events, event.action.weight + count)
    end
  end
end
