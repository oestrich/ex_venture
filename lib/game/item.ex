defmodule Game.Item do
  @moduledoc """
  Help methods for items
  """

  alias Data.Item

  @doc """
  Determine if a lookup string matches the item

  Checks the downcased name and keyword list

  Example:

      iex> Game.Item.matches_lookup?(%{name: "Short Sword", keywords: ["sword"]}, "short sword")
      true

      iex> Game.Item.matches_lookup?(%{name: "Short Sword", keywords: ["sword"]}, "sword")
      true

      iex> Game.Item.matches_lookup?(%{name: "Short Sword", keywords: ["sword"]}, "short")
      false
  """
  @spec matches_lookup?(item :: Item.t, lookup :: String.t) :: Item.t | nil
  def matches_lookup?(item, lookup) do
    [item.name | item.keywords]
    |> Enum.map(&String.downcase/1)
    |> Enum.any?(&(&1 == lookup))
  end
end
