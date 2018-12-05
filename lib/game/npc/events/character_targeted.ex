defmodule Game.NPC.Events.CharacterTargeted do
  @moduledoc """
  Processes the `character/targeted` event
  """

  alias Data.Events.CharacterTargeted
  alias Game.NPC.Actions
  alias Game.NPC.Events

  def process(state, sent_event) do
    state.events
    |> Events.filter(CharacterTargeted)
    |> Enum.each(&process_event(&1, sent_event))

    {:ok, state}
  end

  def process_event(event, sent_event) do
    {"character/targeted", {:from, character}} = sent_event

    event.actions
    |> Actions.add_character(character)
    |> Actions.delay()
  end
end
