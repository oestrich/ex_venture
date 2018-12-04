defmodule Game.NPC.Events.CombatTicked do
  @moduledoc """
  Processes the `character/targeted` event
  """

  alias Data.Events.CombatTicked
  alias Game.NPC.Actions
  alias Game.NPC.Events

  def process(state) do
    state.events
    |> Events.filter(CombatTicked)
    |> select_weighted_event()
    |> process_event(state)

    {:ok, state}
  end

  def process_event(event, state) do
    event.actions
    |> Actions.add_character(state.target)
    |> Actions.delay()
  end

  def select_weighted_event(events) do
    events
    |> expand_events()
    |> Enum.random()
  end

  def expand_events(events) do
    Enum.flat_map(events, fn event ->
      options = Map.get(event, :options, %{})
      case Map.get(options, :weight, 10) do
        0 ->
          []

        weight ->
          Enum.map(1..weight, fn _ -> event end)
      end
    end)
  end
end
