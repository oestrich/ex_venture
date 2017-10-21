defmodule Data.Item.Compiled do
  @moduledoc """
  An item is compiled after the item tags are rolled together and merged
  with the base item's stats.
  """

  alias Data.Item

  @fields [:id, :name, :description, :type, :keywords, :stats, :effects, :drop_rate, :cost]

  defstruct @fields

  @type t :: %__MODULE__{}

  @doc """
  The item's item tags should be preloaded
      Repo.preload(item, [:item_tags])
  """
  def compile(item) do
    __MODULE__
    |> struct(Map.take(item, @fields))
    |> merge_stats(item)
    |> merge_effects(item)
  end

  @doc """
  Merge stats together
  """
  @spec merge_stats(compiled_item :: t(), item :: Item.t) :: t()
  def merge_stats(compiled_item, %{item_tags: item_tags}) do
    stats = Enum.reduce(item_tags, compiled_item.stats, &_merge_stats/2)
    %{compiled_item | stats: stats}
  end

  defp _merge_stats(%{type: "armor", stats: stats}, acc_stats) do
    %{acc_stats | armor: acc_stats.armor + stats.armor}
  end
  defp _merge_stats(_, stats), do: stats

  @doc """
  Concatenate effects of the item and all of its tags
  """
  @spec merge_effects(compiled_item :: t(), item :: Item.t) :: t()
  def merge_effects(compiled_item, %{item_tags: item_tags}) do
    effects = Enum.flat_map(item_tags, &(&1.effects))
    %{compiled_item | effects: compiled_item.effects ++ effects}
  end
end
