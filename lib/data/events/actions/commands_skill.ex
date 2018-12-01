defmodule Data.Events.Actions.CommandsSkill do
  @event_type "commands/skill"

  defstruct [:delay, :options, type: @event_type]

  @behaviour Data.Events.Actions

  @impl true
  def type(), do: @event_type

  @impl true
  def options(), do: [skill: :string]
end
