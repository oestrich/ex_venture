defmodule Game.Effect do
  @moduledoc """
  Calculate and apply effects from skills/items
  """

  alias Data.Effect
  alias Data.Stats
  alias Data.Stats.Damage

  @random_damage Application.get_env(:ex_venture, :game)[:random_damage]

  @doc """
  Calculate effects based on the user

  Filters out stat boosting effects, then deals with damage & recovery

      iex> Game.Effect.calculate(%{}, [])
      []

      iex> Game.Effect.calculate(%{strength: 10}, [%{kind: "damage", type: :slashing, amount: 10}])
      [%{kind: "damage", amount: 15, type: :slashing}]
  """
  @spec calculate(Stats.t(), [Effect.t()]) :: [map()]
  def calculate(stats, effects) do
    {stats, effects} = stats |> calculate_stats(effects)

    {damage_effects, effects} = effects |> Enum.split_with(&(&1.kind == "damage"))
    damage = damage_effects |> Enum.map(&calculate_damage(&1, stats))

    {damage_over_time_effects, effects} =
      effects |> Enum.split_with(&(&1.kind == "damage/over-time"))

    damage_over_time = damage_over_time_effects |> Enum.map(&calculate_damage(&1, stats))

    {recover_effects, effects} = effects |> Enum.split_with(&(&1.kind == "recover"))
    recover = recover_effects |> Enum.map(&calculate_recover(&1, stats))

    {damage_type_effects, _effects} = effects |> Enum.split_with(&(&1.kind == "damage/type"))
    damage = damage_type_effects |> Enum.reduce(damage, &calculate_damage_type/2)

    damage ++ damage_over_time ++ recover
  end

  @doc """
  Calculate stats and return any effects that were not processed

    iex> stats = %{strength: 10}
    iex> effects = [%{kind: "stats", field: :strength, amount: 10}, %{kind: "damage"}]
    iex> Game.Effect.calculate_stats(stats, effects)
    {%{strength: 20}, [%{kind: "damage"}]}
  """
  @spec calculate_stats(Stats.t(), [Effect.t()]) :: Stats.t()
  def calculate_stats(stats, effects) do
    {stat_effects, effects} = effects |> Enum.split_with(&(&1.kind == "stats"))
    stats = stat_effects |> Enum.reduce(stats, &process_stats/2)
    {stats, effects}
  end

  @doc """
  Process stats effects

      iex> Game.Effect.process_stats(%{field: :strength, amount: 10}, %{strength: 10})
      %{strength: 20}
  """
  @spec process_stats(Effect.t(), Stats.t()) :: Stats.t()
  def process_stats(effect, stats)

  def process_stats(%{field: field, amount: amount}, stats) do
    stats |> Map.put(field, stats[field] + amount)
  end

  @doc """
  Calculate damage

  Physical:
      iex> effect = %{kind: "damage", amount: 10, type: :slashing}
      iex> Game.Effect.calculate_damage(effect, %{strength: 10})
      %{kind: "damage", amount: 15, type: :slashing}

  Magical:
      iex> effect = %{kind: "damage", amount: 10, type: :arcane}
      iex> Game.Effect.calculate_damage(effect, %{intelligence: 10})
      %{kind: "damage", amount: 15, type: :arcane}
  """
  @spec calculate_damage(Effect.t(), Stats.t()) :: map()
  def calculate_damage(effect, stats) do
    case Damage.physical?(effect.type) do
      true ->
        strength_modifier = 1 + stats.strength / 20.0 + Enum.random(@random_damage) / 100
        modified_amount = round(Float.ceil(effect.amount * strength_modifier))
        effect |> Map.put(:amount, modified_amount)

      false ->
        intelligence_modifier = 1 + stats.intelligence / 20.0 + Enum.random(@random_damage) / 100
        modified_amount = round(Float.ceil(effect.amount * intelligence_modifier))
        effect |> Map.put(:amount, modified_amount)
    end
  end

  @doc """
  Calculate recovery

      iex> effect = %{kind: "recover", type: "health", amount: 10}
      iex> Game.Effect.calculate_recover(effect, %{wisdom: 10})
      %{kind: "recover", type: "health", amount: 15}
  """
  @spec calculate_recover(Effect.t(), Stats.t()) :: map()
  def calculate_recover(effect, stats) do
    wisdom_modifier = 1 + stats.wisdom / 20.0
    modified_amount = round(Float.ceil(effect.amount * wisdom_modifier))
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
  @spec calculate_damage_type(Effect.t(), Stats.t()) :: map()
  def calculate_damage_type(effect, damages) do
    damages
    |> Enum.map(fn damage ->
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
  Apply effects to stats.

      iex> effects = [%{kind: "damage", type: :slashing, amount: 10}]
      iex> Game.Effect.apply(effects, %{health: 25})
      %{health: 15}
  """
  @spec apply([Effect.t()], Stats.t()) :: Stats.t()
  def apply(effects, stats) do
    effects |> Enum.reduce(stats, &apply_effect/2)
  end

  @doc """
  Apply an effect to stats

      iex> effect = %{kind: "damage", type: :slashing, amount: 10}
      iex> Game.Effect.apply_effect(effect, %{health: 25})
      %{health: 15}
  """
  @spec apply_effect(Effect.t(), Stats.t()) :: Stats.t()
  def apply_effect(effect, stats)

  def apply_effect(effect = %{kind: "damage"}, stats) do
    %{health: health} = stats
    Map.put(stats, :health, health - effect.amount)
  end

  def apply_effect(effect = %{kind: "damage/over-time"}, stats) do
    %{health: health} = stats
    Map.put(stats, :health, health - effect.amount)
  end

  def apply_effect(effect = %{kind: "recover", type: "health"}, stats) do
    %{health: health, max_health: max_health} = stats
    health = max_recover(health, effect.amount, max_health)
    %{stats | health: health}
  end

  def apply_effect(effect = %{kind: "recover", type: "skill"}, stats) do
    %{skill_points: skill_points, max_skill_points: max_skill_points} = stats
    skill_points = max_recover(skill_points, effect.amount, max_skill_points)
    %{stats | skill_points: skill_points}
  end

  def apply_effect(effect = %{kind: "recover", type: "move"}, stats) do
    %{move_points: move_points, max_move_points: max_move_points} = stats
    move_points = max_recover(move_points, effect.amount, max_move_points)
    %{stats | move_points: move_points}
  end

  def apply_effect(_effect, stats), do: stats

  @doc """
  Limit recovery to the max points

      iex> Game.Effect.max_recover(10, 1, 15)
      11

      iex> Game.Effect.max_recover(10, 6, 15)
      15
  """
  @spec max_recover(integer(), integer(), integer()) :: integer()
  def max_recover(current_points, amount, max_points) do
    case current_points + amount do
      current_points when current_points > max_points -> max_points
      current_points -> current_points
    end
  end

  @doc """
  Filters to continuous effects only

  - `damage/over-time`
  """
  @spec continuous_effects([Effect.t()], Character.t()) :: [Effect.t()]
  def continuous_effects(effects, from) do
    effects
    |> Enum.filter(&Effect.continuous?/1)
    |> Enum.map(&Effect.instantiate/1)
    |> Enum.map(fn effect ->
      {from, effect}
    end)
  end
end
