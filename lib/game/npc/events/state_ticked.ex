defmodule Game.NPC.Events.StateTicked do
  @moduledoc """
  Processes the `character/targeted` event
  """

  alias Game.NPC.Actions
  alias Game.NPC.Events

  def process(state, event) do
    Actions.delay(event.actions)
    Events.delay_event(event)

    {:ok, state}
  end
end
