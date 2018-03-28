defmodule Game.Help do
  @moduledoc """
  Find help about a topic
  """

  require Logger

  alias Game.Format
  alias Game.Help.Agent, as: HelpAgent
  alias Game.Skills

  @doc """
  Basic help information

  Which commands can be run.

  Example:

      iex> Regex.match?(~r(^The topics you can look up are:), Game.Help.base())
      true
  """
  def base() do
    commands =
      Game.Command.commands()
      |> Enum.map(fn command ->
        key = command.help(:topic)

        "\t{command send='help #{String.downcase(key)}'}#{key}{/command}: #{command.help(:short)}\n"
      end)

    built_ins =
      HelpAgent.built_in()
      |> Enum.map(fn built_in ->
        "\t{command send='help #{built_in.name}'}#{built_in.name}{/command}: #{built_in.short}\n"
      end)

    topics =
      (commands ++ built_ins)
      |> Enum.sort()
      |> Enum.join("")

    "The topics you can look up are:\n#{topics}"
  end

  @doc """
  Find a help topic whether a command or a database topic
  """
  @spec topic(String.t()) :: String.t()
  def topic(topic) do
    Logger.info("Help looked up for #{inspect(topic)}", type: :topic)
    topic = topic |> String.upcase()

    case find_command(topic) do
      nil -> find_help_topic(topic)
      body -> body
    end
  end

  defp find_command(topic) do
    Game.Command.commands()
    |> Enum.find(&match_command?(&1, topic))
    |> format_command_help()
  end

  defp format_command_help(nil), do: nil

  defp format_command_help(command) do
    lines = [
      command.help(:topic),
      Format.underline(command.help(:topic)),
      " ",
      "Commands: #{command.commands |> Enum.join(", ")}",
      aliases(command),
      " ",
      command.help(:full)
    ]

    lines
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
    |> String.trim()
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

    :topic |> command.help() |> String.downcase() == topic |> String.downcase() ||
      topic in commands || topic in aliases
  end

  defp find_help_topic(topic) do
    help_topic =
      HelpAgent.database()
      |> Enum.find(&match_help_topic?(&1, topic))

    case help_topic do
      nil -> find_built_in_topic(topic)
      help_topic -> format_help_topic(help_topic)
    end
  end

  defp format_help_topic(help_topic) do
    """
    #{help_topic.name}
    Keywords: #{help_topic.keywords |> Enum.join(", ")}

    #{help_topic.body}
    """
    |> String.trim()
  end

  defp match_help_topic?(help_topic, topic) do
    keywords = Enum.map(help_topic.keywords, &String.upcase/1)
    help_topic.name |> String.upcase() == topic || topic in keywords
  end

  def find_built_in_topic(topic) do
    built_in =
      HelpAgent.built_in()
      |> Enum.find(&match_built_in_topic?(&1, topic))

    case built_in do
      nil -> find_skill_topic(topic)
      built_in -> format_built_in_topic(built_in)
    end
  end

  defp match_built_in_topic?(built_in, topic) do
    built_in.name |> String.upcase() == topic
  end

  defp format_built_in_topic(built_in) do
    """
    #{built_in.name}
    #{Format.underline(built_in.name)}

    #{built_in.full}
    """
    |> String.trim()
  end

  def find_skill_topic(topic) do
    case Skills.skill(String.downcase(topic)) do
      nil -> "Unknown topic"
      skill -> format_skill_topic(skill)
    end
  end

  defp format_skill_topic(skill) do
    """
    #{Format.skill_name(skill)} - Level #{skill.level} - #{skill.points} sp
    Command: {command}#{skill.command}{/command}

    #{skill.description}
    """
    |> String.trim()
  end
end
