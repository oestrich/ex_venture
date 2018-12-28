defmodule Game.Format.Abilities do
  @moduledoc """
  Formatting for abilities
  """

  alias Game.Format.Table

  def abilities(abilities) do
    rows =
      abilities
      |> Enum.map(fn instance ->
        [instance.ability.name, instance.points]
      end)

    rows = [["Name", "Points"] | rows]

    Table.format("Skills", rows, [20, 5])
  end
end
