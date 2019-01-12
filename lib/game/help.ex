defmodule Game.Help do
  @moduledoc """
  Find help about a topic
  """

  require Logger

  alias Game.Command
  alias Game.Format.Help, as: FormatHelp
  alias Game.Format.Proficiencies, as: FormatProficiencies
  alias Game.Help.Agent, as: HelpAgent
  alias Game.Proficiencies
  alias Game.Skills

  defmodule Topic do
    @moduledoc false

    defstruct [:name, :short]
  end

  @doc """
  Basic help information

  Which commands can be run.
  """
  def base(player_flags) do
    commands =
      Command.commands()
      |> Enum.filter(&allowed?(&1, player_flags))
      |> Enum.map(fn command ->
        %Topic{name: command.help(:topic), short: command.help(:short)}
      end)

    built_ins =
      HelpAgent.built_in()
      |> Enum.map(fn built_in ->
        %Topic{name: built_in.name, short: built_in.short}
      end)

    topics = commands ++ built_ins
    topics = Enum.sort_by(topics, &(&1.name))

    FormatHelp.base(topics)
  end

  @doc """
  Check if a command is allowed for the player based on their flags
  """
  @spec allowed?(Command.t(), [String.t()]) :: boolean()
  def allowed?(command, player_flags) do
    Enum.empty?(command.required_flags -- player_flags)
  end

  @doc """
  Find a help topic whether a command or a database topic
  """
  @spec topic(String.t(), [String.t()]) :: String.t()
  def topic(topic, flags \\ []) do
    Logger.info("Help looked up for #{inspect(topic)}", type: :topic)
    topic = topic |> String.upcase()

    case find_command_help(topic, flags) do
      nil ->
        find_help_topic(topic)

      body ->
        body
    end
  end

  defp find_command_help(topic, flags) do
    case Enum.find(Command.commands(), &match_command?(&1, topic)) do
      nil ->
        nil

      command ->
        format_command_help(command, flags)
    end
  end

  defp match_command?(command, topic) do
    commands = Enum.map(command.commands, &String.upcase/1)
    aliases = Enum.map(command.aliases, &String.upcase/1)

    String.upcase(command.help(:topic)) == topic ||
      Enum.member?(commands, topic) || Enum.member?(aliases, topic)
  end

  defp format_command_help(command, flags) do
    case allowed?(command, flags) do
      true ->
        FormatHelp.command(command)

      false ->
        "You are not allowed to use this command"
    end
  end

  defp find_help_topic(topic) do
    case Enum.find(HelpAgent.database(), &match_help_topic?(&1, topic)) do
      nil ->
        find_built_in_topic(topic)

      help_topic ->
        FormatHelp.help_topic(help_topic)
    end
  end

  defp match_help_topic?(help_topic, topic) do
    keywords = Enum.map(help_topic.keywords, &String.upcase/1)

    String.upcase(help_topic.name) == topic || Enum.member?(keywords, topic)
  end

  def find_built_in_topic(topic) do
    case Enum.find(HelpAgent.built_in(), &match_built_in_topic?(&1, topic)) do
      nil ->
        find_skill_topic(topic)

      built_in ->
        FormatHelp.built_in_topic(built_in)
    end
  end

  defp match_built_in_topic?(built_in, topic) do
    String.upcase(built_in.name) == topic
  end

  def find_skill_topic(topic) do
    case Skills.skill(String.downcase(topic)) do
      nil ->
        find_proficiency_topic(topic)

      skill ->
        FormatHelp.skill(skill)
    end
  end

  def find_proficiency_topic(topic) do
    proficiency =
      Enum.find(Proficiencies.all(), fn proficiency ->
        String.downcase(proficiency.name) == String.downcase(topic)
      end)

    case proficiency do
      nil ->
        "Unknown topic"

      proficiency ->
        FormatProficiencies.help(proficiency)
    end
  end
end
