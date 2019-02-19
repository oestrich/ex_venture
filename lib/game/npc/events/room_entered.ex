defmodule Game.NPC.Events.RoomEntered do
  @moduledoc """
  Processes the `room/entered` event
  """

  alias Data.Events.RoomEntered
  alias Game.NPC.Actions
  alias Game.NPC.Events

  def process(state, sent_event) do
    state.events
    |> Events.filter(RoomEntered)
    |> Enum.each(&process_event(&1, sent_event))

    {:ok, state}
  end

  def process_event(event, %{character: character}) do
    event.actions
    |> Actions.add_character(character)
    |> Actions.delay()
  end
end
