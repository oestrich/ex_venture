defmodule Data.Events.RoomHeard do
  @event_type "room/heard"

  defstruct [:options, :actions, type: @event_type]

  @behaviour Data.Events

  @impl true
  def type(), do: @event_type

  @impl true
  def allowed_actions() do
    [
      "commands/say",
      "commands/emote"
    ]
  end

  @impl true
  def options(), do: [regex: :string]
end
