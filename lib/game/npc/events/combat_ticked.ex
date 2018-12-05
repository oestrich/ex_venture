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

    delay = Events.calculate_total_delay(event)
    Events.notify_delayed({"combat/ticked"}, delay)
  end

  def select_weighted_event(events) do
    events
    |> expand_events()
    |> Enum.random()
  end

  def expand_events(events) do
    Enum.flat_map(events, &expand_event/1)
  end

  defp expand_event(event) do
    options = Map.get(event, :options, %{})

    case Map.get(options, :weight, 10) do
      0 ->
        []

      weight ->
        Enum.map(1..weight, fn _ -> event end)
    end
  end
end

#   broadcast(npc, "combat/action", %{
#     target: who(target),
#     text: FormatSkills.skill_usee(action.text, user: npc(state), target: target),
#     effects: effects
#   })
