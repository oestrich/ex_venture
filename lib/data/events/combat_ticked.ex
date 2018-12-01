defmodule Data.Events.CombatTicked do
  @event_type "combat/ticked"

  @derive Jason.Encoder
  defstruct [:id, :options, :actions, type: @event_type]

  @behaviour Data.Events

  @impl true
  def type(), do: @event_type

  @impl true
  def allowed_actions(), do: ["commands/skill"]

  @impl true
  def options(), do: [weight: :integer]
end
