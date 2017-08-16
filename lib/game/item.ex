defmodule Game.Item do
  @moduledoc """
  Help methods for items
  """

  alias Data.Item
  alias Game.Items

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

  @doc """
  Find an item in a list of items

  Example:

      iex> Game.Item.find_item([%{name: "Short sword", keywords: ["sword"]}], "sword")
      %{name: "Short sword", keywords: ["sword"]}

      iex> Game.Item.find_item([%{name: "Sword", keywords: []}, %{name: "Shield", keywords: []}], "shield")
      %{name: "Shield", keywords: []}

      iex> Game.Item.find_item([%{name: "Sword", keywords: []}], "shield")
      nil
  """
  @spec find_item(items :: [Item.t], item_name :: String.t) :: Item.t | nil
  def find_item(items, item_name) do
    Enum.find(items, &(Game.Item.matches_lookup?(&1, item_name)))
  end

  @doc """
  Find all effects from what the player is wearing
  """
  @spec effects_from_wearing(save :: Save.t) :: [Effect.t]
  def effects_from_wearing(%{wearing: wearing}) do
    wearing |> Enum.flat_map(fn ({_slot, item_id}) -> Items.item(item_id).effects end)
  end
  def effects_from_wearing(_), do: []
end
