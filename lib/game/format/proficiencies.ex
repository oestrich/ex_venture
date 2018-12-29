defmodule Game.Format.Proficiencies do
  @moduledoc """
  Formatting for proficiencies
  """

  alias Game.Format.Table

  def proficiencies(proficiencies) do
    rows =
      proficiencies
      |> Enum.map(fn instance ->
        [instance.proficiency.name, instance.points]
      end)

    rows = [["Name", "Points"] | rows]

    Table.format("Proficiencies", rows, [20, 5])
  end
end
