defmodule Game.Item do
  @moduledoc """
  Help methods for items
  """

  alias Data.Item
  alias Game.Items
  alias Game.Utility

  @doc """
  Determine if a lookup string matches the item

  Checks the downcased name and keyword list

  Example:

      iex> Game.Item.matches_lookup?(%{name: "Short Sword", keywords: ["sword"]}, "short sword")
      true

      iex> Game.Item.matches_lookup?(%{name: "Short Sword", keywords: ["sword"]}, "sword")
      true

      iex> Game.Item.matches_lookup?(%{name: "Short Sword", keywords: ["sword"]}, "dagger")
      false
  """
  @spec matches_lookup?(Item.t(), String.t()) :: Item.t() | nil
  def matches_lookup?(item, lookup) do
    [item.name | item.keywords]
    |> Enum.map(&String.downcase/1)
    |> Enum.any?(&Utility.matches?(&1, lookup))
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
  @spec find_item([Item.t()], String.t()) :: Item.t() | nil
  def find_item(items, item_name) do
    Enum.find(items, fn
      {_instance, item} -> matches_lookup?(item, item_name)
      item -> matches_lookup?(item, item_name)
    end)
  end

  @doc """
  Get all effects on the player (wearing & wielded)
  """
  @spec effects_on_player(Save.t(), Keyword.t()) :: [Effect.t()]
  def effects_on_player(save, opts \\ []) do
    wearing_effects = save |> effects_from_wearing(opts)
    wielding_effects = save |> effects_from_wielding(opts)
    wearing_effects ++ wielding_effects
  end

  @doc """
  Find all effects from what the player is wearing
  """
  @spec effects_from_wearing(Save.t(), Keyword.t()) :: [Effect.t()]
  def effects_from_wearing(save, opts \\ [])

  def effects_from_wearing(%{wearing: wearing}, opts) do
    wearing
    |> Enum.flat_map(fn {_slot, instance} -> Items.item(instance).effects end)
    |> Enum.filter(&_filter_by_kind(&1, opts))
  end

  def effects_from_wearing(_, _), do: []

  @doc """
  Find all effects from what the player is wielding
  """
  @spec effects_from_wielding(Save.t(), Keyword.t()) :: [Effect.t()]
  def effects_from_wielding(save, opts \\ [])

  def effects_from_wielding(%{wielding: wielding}, opts) do
    wielding
    |> Enum.flat_map(fn {_slot, instance} -> Items.item(instance).effects end)
    |> Enum.filter(&_filter_by_kind(&1, opts))
  end

  def effects_from_wielding(_, _), do: []

  defp _filter_by_kind(effect, opts) do
    case Keyword.get(opts, :only, nil) do
      nil -> true
      kinds -> effect.kind in kinds
    end
  end

  @doc """
  Remove an item from a list of instantiated items

      iex> item = %Data.Item{id: 1}
      iex> instance = Data.Item.instantiate(item)
      iex> Game.Item.remove([instance], item) == {instance, []}
      true
  """
  @spec remove([Item.instance()], Item.t()) :: {Item.instance(), [Item.instance()]}
  def remove(items, item) do
    instance = items |> Enum.find(&(&1.id == item.id))
    {instance, List.delete(items, instance)}
  end

  @doc """
  Migrate an instance of an item
  """
  @spec migrate_instance(Item.instance()) :: Item.instance()
  def migrate_instance(instance) do
    item = Items.item(instance)

    case item.is_usable do
      true -> ensure_amount(instance, item)
      false -> instance
    end
  end

  defp ensure_amount(instance = %{amount: nil}, item) do
    %{instance | amount: item.amount}
  end

  defp ensure_amount(instance, _item), do: instance

  @doc """
  Get all items on a player
  """
  @spec all_items(Save.t()) :: [Item.instance()]
  def all_items(save) do
    wearing =
      save.wearing
      |> Enum.map(fn {_slot, instance} -> instance end)

    wielding =
      save.wielding
      |> Enum.map(fn {_slot, instance} -> instance end)

    save.items ++ wearing ++ wielding
  end

  @doc """
  Filter out effects that don't match the items's whitelist
  """
  @spec filter_effects([Effect.t()], Item.t()) :: [Effect.t()]
  def filter_effects(effects, item) do
    Enum.filter(effects, fn effect ->
      effect.kind in item.whitelist_effects
    end)
  end
end
