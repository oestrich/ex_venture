defmodule Data.Events.Actions.CommandsSay do
  @event_type "commands/say"

  defstruct [:delay, :options, type: @event_type]

  @behaviour Data.Events.Actions

  @impl true
  def type(), do: @event_type

  @impl true
  def options(), do: [message: :string, messages: {:array, :string}]
end
