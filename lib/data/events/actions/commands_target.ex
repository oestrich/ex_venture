defmodule Data.Events.Actions.CommandsTarget do
  @moduledoc """
  `commands/target` action
  """

  @event_type "commands/target"

  @derive Jason.Encoder
  defstruct [:delay, :options, type: @event_type]

  @behaviour Data.Events.Actions

  @impl true
  def type(), do: @event_type

  @impl true
  def options(), do: []
end
