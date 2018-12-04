defmodule Game.NPC.Events.RoomEntered do
  @moduledoc """
  Processes the `room/heard` event
  """

  alias Data.Events.RoomEntered
  alias Game.NPC.Actions
  alias Game.NPC.Events

  def process(state, sent_event) do
    state.events
    |> Events.filter(RoomEntered)
    |> Enum.map(&process_event(&1, sent_event))

    {:ok, state}
  end

  def process_event(event, sent_event) do
    {"room/entered", {character, _direction}} = sent_event

    event.actions
    |> Actions.add_character(character)
    |> Actions.delay()
  end
end
