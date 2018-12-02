defmodule Data.Events.CharacterTargeted do
  @moduledoc """
  `character/targeted` event
  """

  @event_type "character/targeted"

  @derive Jason.Encoder
  defstruct [:id, :options, :actions, type: @event_type]

  @behaviour Data.Events

  @impl true
  def type(), do: @event_type

  @impl true
  def allowed_actions(), do: ["commands/target"]

  @impl true
  def options(), do: []
end
