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
end
