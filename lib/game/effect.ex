defmodule Game.Effect do
  @moduledoc """
  Calculate and apply effects from skills/items
  """

  alias Data.Effect
  alias Data.Stats

  @doc """
  Calculate effects based on the user

      iex> Game.Effect.calculate(%{}, %{})
      []

      iex> Game.Effect.calculate(%{strength: 10}, [%{kind: "damage", type: :slashing, amount: 10}])
      [%{kind: "damage", amount: 11, type: :slashing}]
  """
  @spec calculate(stats :: Stats.t, effects :: [Effect.t]) :: [map]
  def calculate(stats, effects) do
    effects
    |> order_effects()
    |> Enum.map(&(calculate_effect(&1, stats)))
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
    effect
    |> Map.put(:amount, modified_amount)
  end

  @doc """
  Order effects

      iex> Game.Effect.order_effects([%{kind: "damage"}])
      [%{kind: "damage"}]
  """
  @spec order_effects(effects :: [Effect.t]) :: [Effect.t]
  def order_effects(effects) do
    effects
  end
end
