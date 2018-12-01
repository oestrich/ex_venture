defmodule Data.Events.RoomEntered do
  @event_type "room/entered"

  @derive Jason.Encoder
  defstruct [:id, :options, :actions, type: @event_type]

  @behaviour Data.Events

  @impl true
  def type(), do: @event_type

  @impl true
  def allowed_actions(), do: ["commands/emote", "commands/say", "commands/target"]

  @impl true
  def options(), do: []
end
