defmodule Game.Format.Hone do
  @moduledoc """
  Formatting around honing stats and proficiencies
  """

  import Game.Format.Context

  alias Game.Command.Hone
  alias Game.Format

  def help(save, spendable_experience) do
    context()
    |> assign(:strength, hone_field_help(save, :strength, "Strength"))
    |> assign(:agility, hone_field_help(save, :agility, "Agility"))
    |> assign(:intelligence, hone_field_help(save, :intelligence, "Intelligence"))
    |> assign(:awareness, hone_field_help(save, :awareness, "Awareness"))
    |> assign(:vitality, hone_field_help(save, :vitality, "Vitality"))
    |> assign(:willpower, hone_field_help(save, :willpower, "Willpower"))
    |> assign(:health, hone_points_help(save, :health, "Health"))
    |> assign(:skill, hone_points_help(save, :skill, "Skill"))
    |> assign(:endurance, hone_points_help(save, :endurance, "Endurance"))
    |> assign(:spendable_experience, spendable_experience)
    |> assign(:hone_cost, Hone.hone_cost())
    |> Format.template(template("help"))
  end

  def hone_field_help(save, field, title) do
    stat = Map.get(save.stats, field)

    context()
    |> assign(:field, field)
    |> assign(:stat, stat)
    |> assign(:title, title)
    |> assign(:boost, Hone.hone_stat_boost())
    |> Format.template(template("field-help"))
  end

  def hone_points_help(save, field, title) do
    stat = Map.get(save.stats, String.to_atom("max_#{field}_points"))

    context()
    |> assign(:field, field)
    |> assign(:stat, stat)
    |> assign(:title, title)
    |> assign(:boost, Hone.hone_points_boost())
    |> Format.template(template("points-help"))
  end

  def template("help") do
    """
    Which statistic do you want to hone?

    [strength]
    [agility]
    [intelligence]
    [awareness]
    [vitality]
    [willpower]
    [health]
    [skill]
    [endurance]

    You can also hone your {command send='help proficiencies'}Proficiencies{/command}. Honing a proficiency will increase your rank by 1.

    Honing costs [hone_cost] xp. You have [spendable_experience] xp left to spend.
    """
  end

  def template("field-help") do
    String.trim("""
    {command send='hone [field]'}[title]{/command}
      Your [field] is currently at [stat], honing will add {yellow}[boost]{/yellow}
    """)
  end

  def template("points-help") do
    String.trim("""
    {command send='hone [field]'}[title]{/command} Points
      Your max [field] points are currently at [stat], honing will add {yellow}[boost]{/yellow}
    """)
  end
end
