defmodule Data.Item.Compiled do
  @moduledoc """
  An item is compiled after the item aspects are rolled together and merged
  with the base item's stats.
  """

  alias Data.Item

  @fields [:id, :level, :name, :description, :type, :keywords, :stats, :effects, :cost, :user_text, :usee_text]

  defstruct @fields

  @type t :: %__MODULE__{}

  @doc """
  The item's item aspects should be preloaded
      Repo.preload(item, [item_aspectings: [:item_aspect]])
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
  def merge_stats(compiled_item, %{item_aspectings: item_aspectings}) do
    stats = Enum.reduce(item_aspectings, compiled_item.stats, &(_merge_stats(&1, &2, compiled_item.level)))
    %{compiled_item | stats: stats}
  end

  defp _merge_stats(%{item_aspect: %{type: "armor", stats: stats}}, acc_stats, level) do
    armor = scale_for_level(level, stats.armor)
    %{acc_stats | armor: acc_stats.armor + armor}
  end
  defp _merge_stats(_, stats, _), do: stats

  @doc """
  Concatenate effects of the item and all of its tags
  """
  @spec merge_effects(compiled_item :: t(), item :: Item.t) :: t()
  def merge_effects(compiled_item, %{item_aspectings: item_aspectings}) do
    effects = Enum.flat_map(item_aspectings, &(_scale_effects(&1, compiled_item.level)))
    %{compiled_item | effects: compiled_item.effects ++ effects}
  end

  defp _scale_effects(%{item_aspect: %{effects: effects}}, level) do
    Enum.map(effects, &(_scale_effect(&1, level)))
  end

  def _scale_effect(effect = %{kind: "damage"}, level) do
    %{effect | amount: scale_for_level(level, effect.amount)}
  end
  def _scale_effect(effect, _level), do: effect

  @doc """
  Scales a value for a level. Every 10 levels the value will double

      iex> Data.Item.Compiled.scale_for_level(1, 5)
      5
      iex> Data.Item.Compiled.scale_for_level(11, 5)
      10
      iex> Data.Item.Compiled.scale_for_level(11, 10)
      20
  """
  def scale_for_level(level, value) do
    round(Float.ceil(value * (1 + ((level - 1) / 10))))
  end
end
