defmodule Game.Help do
  @moduledoc """
  Find help about a topic
  """

  @doc """
  Basic help information

  Which commands can be run.

  Example:

      iex> Regex.match?(~r(^The topics you can look up are:), Game.Help.base())
      true
  """
  def base() do
    commands = Game.Command.commands
    |> Enum.map(fn (command) ->
      key = command |> command_topic_key()
      "\t{white}#{key}{/white}: #{command.help[:short]}\n"
    end)
    |> Enum.join("")

    "The topics you can look up are:\n#{commands}"
  end

  @spec topic(topic :: String.t) :: String.t
  def topic(topic) do
    topic = topic |> String.upcase

    command = Game.Command.commands
    |> Enum.find(&(match_command?(&1, topic)))

    case command do
      nil -> "Unknown topic"
      command ->
        lines = [
          "Commands: #{command.commands |> Enum.join(", ")}",
          aliases(command),
          " ",
          command.help.full,
        ]

        lines
        |> Enum.reject(&(&1 == ""))
        |> Enum.join("\n")
        |> String.trim
    end
  end

  defp aliases(command) do
    case command.aliases do
      [] ->
        ""
      aliases ->
        "Aliases: #{aliases |> Enum.join(", ")}"
    end
  end

  defp match_command?(command, topic) do
    commands = command.commands |> Enum.map(&String.upcase/1)
    aliases = command.aliases |> Enum.map(&String.upcase/1)

    command |> command_topic_key == topic |> String.upcase
      || topic in commands
      || topic in aliases
  end

  defp command_topic_key(command) do
    command |> to_string |> String.split(".") |> List.last |> String.upcase
  end
end
