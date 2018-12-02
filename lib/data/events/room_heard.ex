defmodule Data.Events.RoomHeard do
  @moduledoc """
  `room/heard` event
  """

  @event_type "room/heard"

  @derive Jason.Encoder
  defstruct [:id, :options, :actions, type: @event_type]

  @behaviour Data.Events

  @impl true
  def type(), do: @event_type

  @impl true
  def allowed_actions(), do: ["commands/say", "commands/emote"]

  @impl true
  def options(), do: [regex: :string]
end
