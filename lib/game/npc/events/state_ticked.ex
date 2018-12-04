defmodule Game.NPC.Events.StateTicked do
  @moduledoc """
  Processes the `character/targeted` event
  """

  alias Game.NPC.Actions

  def process(state, event) do
    Actions.delay(event.actions)

    {:ok, state}
  end
end
