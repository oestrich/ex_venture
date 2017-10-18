defmodule Game.Help do
  @moduledoc """
  Find help about a topic
  """

  require Logger

  alias Game.Help.Agent, as: HelpAgent

  @doc """
  Basic help information

  Which commands can be run.

  Example:

      iex> Regex.match?(~r(^The topics you can look up are:), Game.Help.base())
      true
  """
  def base() do
    commands = Game.Command.commands
    |> Enum.sort_by(&command_topic_key/1)
    |> Enum.map(fn (command) ->
      key = command |> command_topic_key()
      "\t{white}#{key}{/white}: #{command.help[:short]}\n"
    end)
    |> Enum.join("")

    "The topics you can look up are:\n#{commands}"
  end

  @doc """
  Find a help topic whether a command or a database topic
  """
  @spec topic(topic :: String.t) :: String.t
  def topic(topic) do
    Logger.info("Help looked up for #{inspect(topic)}", type: :topic)
    topic = topic |> String.upcase
    case find_command(topic) do
      nil -> find_help_topic(topic)
      body -> body
    end
  end

  defp find_command(topic) do
    Game.Command.commands
    |> Enum.find(&(match_command?(&1, topic)))
    |> format_command_help()
  end

  defp format_command_help(nil), do: nil
  defp format_command_help(command) do
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

    command |> command_topic_key |> String.downcase == topic |> String.downcase
      || topic in commands
      || topic in aliases
  end

  defp command_topic_key(command) do
    command.help()[:topic]
  end

  defp find_help_topic(topic) do
    help_topic = HelpAgent.all()
    |> Enum.find(&(match_help_topic?(&1, topic)))

    format_help_topic(help_topic)
  end

  defp format_help_topic(nil), do: "Unknown topic"
  defp format_help_topic(help_topic) do
    """
    #{help_topic.name}
    Keywords: #{help_topic.keywords |> Enum.join(", ")}

    #{help_topic.body}
    """ |> String.trim
  end

  defp match_help_topic?(help_topic, topic) do
    keywords = Enum.map(help_topic.keywords, &String.upcase/1)
    help_topic.name |> String.upcase == topic
      || topic in keywords
  end
end
