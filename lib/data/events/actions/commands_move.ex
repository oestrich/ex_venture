defmodule Data.Events.Actions.CommandsMove do
  @moduledoc """
  `commands/move` action
  """

  @event_type "commands/move"

  @derive Jason.Encoder
  defstruct [:delay, options: %{}, type: @event_type]

  @behaviour Data.Events.Actions

  @impl true
  def type(), do: @event_type

  @impl true
  def options(), do: [max_distance: :integer]
end
