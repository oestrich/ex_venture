defmodule Data.Events.Actions.ChannelsSay do
  @event_type "channels/say"

  defstruct [:delay, :options, type: @event_type]

  @behaviour Data.Events.Actions

  @impl true
  def type(), do: @event_type

  @impl true
  def options(), do: [message: :string, messages: {:array, :string}]
end
