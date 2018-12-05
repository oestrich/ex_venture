defmodule Data.Events.Actions do
  @moduledoc """
  Actions that can be triggered when an event fires

  Possible actions:
  - `commands/emote`
  - `commands/move`
  - `commands/say`
  - `commands/skill`
  - `commands/target`
  """

  @type options_mapping :: map()

  @callback type() :: String.t()

  @callback options :: options_mapping()

  alias Data.Events.Actions.CommandsEmote
  alias Data.Events.Actions.CommandsMove
  alias Data.Events.Actions.CommandsSay
  alias Data.Events.Actions.CommandsSkill
  alias Data.Events.Actions.CommandsTarget
  alias Data.Events.Options

  @mapping %{
    "commands/emote" => CommandsEmote,
    "commands/move" => CommandsMove,
    "commands/say" => CommandsSay,
    "commands/skill" => CommandsSkill,
    "commands/target" => CommandsTarget
  }

  def mapping(), do: @mapping

  def parse(action) do
    with {:ok, action_type} <- find_type(action),
         {:ok, delay} <- parse_delay(action),
         {:ok, options} <- parse_options(action_type, action) do
      {:ok, struct(action_type, %{options: options, delay: delay})}
    end
  end

  defp find_type(action) do
    case @mapping[action["type"]] do
      nil ->
        {:error, :no_type}

      action_type ->
        {:ok, action_type}
    end
  end

  defp parse_delay(action) do
    delay = Map.get(action, "delay")

    case delay != nil && (is_integer(delay) || is_float(delay)) do
      true ->
        {:ok, delay}

      false ->
        {:ok, 0}
    end
  end

  defp parse_options(action_type, action) do
    with {:ok, options} <- Map.fetch(action, "options"),
         {:ok, options} <- Options.validate_options(action_type, options) do
      {:ok, options}
    else
      :error ->
        {:ok, %{}}

      {:error, errors} ->
        {:error, :invalid_options, errors}
    end
  end
end
