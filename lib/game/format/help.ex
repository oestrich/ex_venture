defmodule Game.Format.Help do
  @moduledoc """
  Format functions for in game help
  """

  import Game.Format.Context

  alias Game.Format

  def base(topics) do
    context()
    |> assign_many(:topics, topics, &topic/1)
    |> Format.template(template("base"))
  end

  def topic(topic) do
    context()
    |> assign(:name, topic.name)
    |> assign(:command, String.downcase(topic.name))
    |> assign(:short, topic.short)
    |> Format.template(template("topic"))
  end

  def command(command) do
    context()
    |> assign(:name, command.help(:topic))
    |> assign(:underline, Format.underline(command.help(:topic)))
    |> assign(:commands, Enum.join(command.commands, ", "))
    |> assign(:aliases, Enum.join(command.aliases, ", "))
    |> assign(:full, command.help(:full))
    |> Format.template(template("command"))
  end

  def help_topic(help) do
    context()
    |> assign(:name, help.name)
    |> assign(:keywords, Enum.join(help.keywords, ", "))
    |> assign(:body, help.body)
    |> Format.template(template("help-topic"))
  end

  def built_in_topic(built_in) do
    context()
    |> assign(:name, built_in.name)
    |> assign(:underline, Format.underline(built_in.name))
    |> assign(:full, built_in.full)
    |> Format.template(template("built-in"))
  end

  def skill(skill) do
    context()
    |> assign(:name, Format.skill_name(skill))
    |> assign(:level, skill.level)
    |> assign(:points, skill.points)
    |> assign(:command, skill.command)
    |> assign(:description, skill.description)
    |> Format.template(template("skill"))
  end

  def template("base") do
    """
    The topics you can look up are:
    [topics]
    """
  end

  def template("topic") do
    "\t{command send='help [command]'}[name]{/command}: [short]"
  end

  def template("command") do
    """
    [name]
    [underline]

    Commands: [commands]
    Aliases: [aliases]

    [full]
    """
  end

  def template("built-in") do
    """
    [name]
    [underline]

    [full]
    """
  end

  def template("help-topic") do
    """
    [name]
    Keywords: [keywords]

    [body]
    """
  end

  def template("skill") do
    """
    [name] - Level [level] - [points] sp
    Command: {command}[command]{/command}

    [description]
    """
  end
end
