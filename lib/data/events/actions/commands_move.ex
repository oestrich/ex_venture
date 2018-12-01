defmodule Data.Events.Actions.CommandsMove do
  @event_type "commands/move"

  defstruct [:delay, :options, type: @event_type]

  @behaviour Data.Events.Actions

  @impl true
  def type(), do: @event_type

  @impl true
  def options(), do: [max_distance: :integer]
end
