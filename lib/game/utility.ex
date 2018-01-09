defmodule Game.Utility do
  @moduledoc """
  Utility functions, such as common string matching
  """

  @doc """
  Determine if a lookup string matches the npc's name

  Checks the downcased name

  Example:

      iex> Game.Utility.matches?(%{name: "Tree Stand Shop"}, "tree stand shop")
      true

      iex> Game.Utility.matches?(%{name: "Tree Stand Shop"}, "tree sta")
      true

      iex> Game.Utility.matches?(%{name: "Tree Stand Shop"}, "hole in the")
      false
  """
  @spec matches?(map(), String.t()) :: boolean()
  def matches?(shop, lookup) do
    String.starts_with?(shop.name |> String.downcase(), lookup |> String.downcase())
  end
end
