defmodule Data.Events.Actions.CommandsSay do
  @moduledoc """
  `commands/say` action
  """

  @event_type "commands/say"

  @derive Jason.Encoder
  defstruct [:delay, options: %{}, type: @event_type]

  @behaviour Data.Events.Actions

  @impl true
  def type(), do: @event_type

  @impl true
  def options(), do: [room_id: :integer, message: :string, messages: {:array, :string}]
end
