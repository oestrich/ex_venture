defmodule Game.Format.Proficiencies do
  @moduledoc """
  Formatting for proficiencies
  """

  import Game.Format.Context

  alias Game.Format
  alias Game.Format.Table

  def name(proficiency) do
    context()
    |> assign(:name, proficiency.name)
    |> Format.template("{white}[name]{/white}")
  end

  def proficiencies(proficiencies) do
    rows =
      proficiencies
      |> Enum.map(fn instance ->
        [instance.name, instance.ranks]
      end)

    rows = [["Name", "Ranks"] | rows]

    Table.format("Proficiencies", rows, [20, 5])
  end

  def help(proficiency) do
    context()
    |> assign(:name, name(proficiency))
    |> assign(:description, proficiency.description)
    |> Format.template("[name] - Proficiency\n\n[description]")
  end

  def missing_requirements(direction, requirements) do
    context()
    |> assign(:direction, direction)
    |> assign_many(:requirements, requirements, &requirement_line/1)
    |> Format.template(template("missing-requirements"))
  end

  def requirement_line(requirement) do
    context()
    |> assign(:name, name(requirement))
    |> assign(:ranks, requirement.ranks)
    |> Format.template(template("requirement-line"))
  end

  def template("requirement-line") do
    " - [name], [ranks]"
  end

  def template("missing-requirements") do
    """
    You cannot move [direction]. You are missing:

    [requirements]
    """
  end
end
