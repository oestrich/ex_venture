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
    {stat_effects, effects} = effects |> Enum.split_with(&(&1.kind == "stats"))
    {damage_effects, effects} = effects |> Enum.split_with(&(&1.kind == "damage"))
    {damage_type_effects, _effects} = effects |> Enum.split_with(&(&1.kind == "damage/type"))

    stats = stat_effects |> Enum.reduce(stats, &process_stats/2)
    damage = damage_effects |> Enum.map(&(calculate_damage(&1, stats)))
    damage_type_effects |> Enum.reduce(damage, &calculate_damage_type/2)
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

  @doc """
  Calculate damage

  Damage:
      iex> effect = %{kind: "damage", amount: 10, type: :slashing}
      iex> Game.Effect.calculate_damage(effect, %{strength: 10})
      %{kind: "damage", amount: 11, type: :slashing}
  """
  @spec calculate_damage(effect :: Effect.t, stats :: Stats.t) :: map
  def calculate_damage(effect, stats) do
    strength_modifier = 1 + (stats.strength / 100.0)
    modified_amount = round(Float.ceil(effect.amount * strength_modifier))
    effect |> Map.put(:amount, modified_amount)
  end

  @doc """
  Calculate damage type effects

  Damage:
      iex> effect = %{kind: "damage/type", types: [:slashing]}
      iex> damage = %{kind: "damage", amount: 10, type: :bludgeoning}
      iex> Game.Effect.calculate_damage_type(effect, [damage])
      [%{kind: "damage", amount: 5, type: :bludgeoning}]
  """
  @spec calculate_damage_type(effect :: Effect.t, stats :: Stats.t) :: map
  def calculate_damage_type(effect, damages) do
    damages
    |> Enum.map(fn (damage) ->
      case damage.type in effect.types do
        true ->
          damage
        false ->
          amount = round(Float.ceil(damage.amount / 2.0))
          %{damage | amount: amount}
      end
    end)
  end

  @doc """
  Apply effects to stats

      iex> effects = [%{kind: "damage", type: :slashing, amount: 10}]
      iex> Game.Effect.apply(effects, %{health: 25})
      %{health: 15}
  """
  @spec apply(effects :: [Effect.t], stats :: Stats.t) :: Stats.t
  def apply(effects, stats) do
    effects |> Enum.reduce(stats, &apply_effect/2)
  end

  @doc """
  Apply an effect to stats

      iex> effect = %{kind: "damage", type: :slashing, amount: 10}
      iex> Game.Effect.apply_effect(effect, %{health: 25})
      %{health: 15}
  """
  @spec apply_effect(effect :: Effect.t, stats :: Stats.t) :: Stats.t
  def apply_effect(effect, stats)
  def apply_effect(effect = %{kind: "damage"}, stats) do
    %{health: health} = stats
    Map.put(stats, :health, health - effect.amount)
  end
  def apply_effect(_effect, stats), do: stats
end
