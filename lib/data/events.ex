defmodule Data.Events do
  @moduledoc """
  Eventing layer

  An event looks like this:

  ```json
  {
    "type": "room/entered",
    "actions": [
      {
        "type": "communications/emote",
        "delay": 0.5,
        "options": {
          "message": "[name] glances up from reading his paper",
        }
      },
      {
        "type": "communications/say",
        "delay": 0.75,
        "options": {
          "message": "Welcome!"
        }
      },
      {
        "type": "communications/say",
        "delay": 0.75,
        "options": {
          "message": "How can I help you?"
        }
      }
    ]
  }
  ```
  """

  @type action :: String.t()

  @type options_mapping :: map()

  @callback type() :: String.t()

  @callback allowed_actions() :: [action()]

  @callback options :: options_mapping()

  alias Data.Events.Actions
  alias Data.Events.Options
  alias Data.Events.RoomEntered
  alias Data.Events.RoomHeard

  @mapping %{
    "room/entered" => RoomEntered,
    "room/heard" => RoomHeard,
  }

  def mapping(), do: @mapping

  def parse(event) do
    with {:ok, event_type} <- find_type(event),
         {:ok, options} <- parse_options(event_type, event),
         {:ok, actions} <- parse_actions(event_type, event) do
      {:ok, struct(event_type, %{options: options, actions: actions})}
    end
  end

  defp find_type(event) do
    case @mapping[event["type"]] do
      nil ->
        {:error, :no_type}

      event_type ->
        {:ok, event_type}
    end
  end

  defp parse_options(event_type, event) do
    with {:ok, options} <- Map.fetch(event, "options"),
         {:ok, options} <- Options.validate_options(event_type, options) do
      {:ok, options}
    else
      :error ->
        {:ok, %{}}

      {:error, errors} ->
        {:error, :invalid_options, errors}
    end
  end

  defp parse_actions(event_type, event) do
    with {:ok, actions} <- Map.fetch(event, "actions") do
      actions =
        actions
        |> Enum.map(&Actions.parse/1)
        |> Enum.filter(&elem(&1, 0) == :ok)
        |> Enum.map(&elem(&1, 1))
        |> Enum.filter(&action_allowed?(event_type, &1.type))

      {:ok, actions}
    else
      :error ->
        {:ok, []}
    end
  end

  @doc """
  Check if an action type is allowed in an event
  """
  def action_allowed?(event_type, action_type) do
    Enum.member?(event_type.allowed_actions(), action_type)
  end
end
