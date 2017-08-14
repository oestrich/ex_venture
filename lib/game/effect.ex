defmodule Game.Effect do
  @moduledoc """
  Calculate and apply effects from skills/items
  """

  alias Data.Effect
  alias Data.Stats

  @doc """
  Calculate effects based on the user

  Filters out stat boosting effects, then deals with damage

      iex> Game.Effect.calculate(%{}, [])
      []

      iex> Game.Effect.calculate(%{strength: 10}, [%{kind: "damage", type: :slashing, amount: 10}])
      [%{kind: "damage", amount: 11, type: :slashing}]
  """
  @spec calculate(stats :: Stats.t, effects :: [Effect.t]) :: [map]
  def calculate(stats, effects) do
    {stat_effects, other_effects} = effects |> Enum.split_with(&(&1.kind == "stats"))
    stats = stat_effects |> Enum.reduce(stats, &process_stats/2)
    other_effects |> Enum.map(&(calculate_effect(&1, stats)))
  end

  @doc """
  Calculate an effect

  Damage:
      iex> effect = %{kind: "damage", amount: 10, type: :slashing}
      iex> Game.Effect.calculate_effect(effect, %{strength: 10})
      %{kind: "damage", amount: 11, type: :slashing}
  """
  @spec calculate_effect(effect :: Effect.t, stats :: Stats.t) :: map
  def calculate_effect(effect, stats)
  def calculate_effect(effect = %{kind: "damage"}, stats) do
    strength_modifier = 1 + (stats.strength / 100.0)
    modified_amount = round(Float.ceil(effect.amount * strength_modifier))
    effect |> Map.put(:amount, modified_amount)
  end


  @doc """
  Process stats effects

      iex> Game.Effect.process_stats(%{field: :strength, amount: 10}, %{strength: 10})
      %{strength: 20}
  """
  @spec process_stats(effect :: Effect.t, stats :: Stats.t) :: Stats.t
  def process_stats(effect, stats)
  def process_stats(%{field: field, amount: amount}, stats) do
    stats |> Map.put(field, stats[field] + amount)
  end
end
