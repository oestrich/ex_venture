defmodule Data.Events.Actions.CommandsEmote do
  @event_type "commands/emote"

  @derive Jason.Encoder
  defstruct [:delay, :options, type: @event_type]

  @behaviour Data.Events.Actions

  @impl true
  def type(), do: @event_type

  @impl true
  def options(), do: [message: :string, status_key: :string, status_line: :string, status_listen: :string]
end
