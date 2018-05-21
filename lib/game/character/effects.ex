defmodule Game.Character.Effects do
  @moduledoc """
  Common effects functions for characters
  """

  require Logger

  alias Data.Stat
  alias Game.Character
  alias Game.Character.State
  alias Game.Effect

  @doc """
  Common character effect application
  """
  @spec apply_effects(Character.t(), Stats.t(), State.t(), [Effect.t()], Character.t()) ::
    {Stat.t(), [Effect.t()], [Effect.continuous_effect()]}
  def apply_effects(character, stats, state, effects, from) do
    continuous_effects = effects |> Effect.continuous_effects(from)

    effects =
      effects
      |> Effect.add_current_continuous_effects(state)
      |> Effect.adjust_effects(stats)

    stats = effects |> Effect.apply(stats)

    from |> Character.effects_applied(effects, character)

    Enum.each(continuous_effects, fn {_from, effect} ->
      Logger.debug(fn ->
        "Maybe delaying effect (#{effect.id})"
      end, type: :character)

      effect |> Effect.maybe_tick_effect(self())
    end)

    {stats, effects, continuous_effects}
  end

  @doc """
  Apply a continuous effect to a character's stats
  """
  @spec apply_continuous_effect(Stats.t(), State.t(), Effect.t()) :: {Stats.t(), [Effect.t()]}
  def apply_continuous_effect(stats, state, effect) do
    effects =
      [effect]
      |> Effect.add_current_continuous_effects(state)
      |> Effect.adjust_effects(stats)

    stats = Effect.apply(effects, stats)

    {stats, effects}
  end

  @doc """
  Clear a continuous effect after its duration is over
  """
  @spec clear_continuous_effect(State.t(), String.t()) :: State.t()
  def clear_continuous_effect(state, effect_id) do
    continuous_effects = Enum.reject(state.continuous_effects, fn {_from, effect} ->
      effect.id == effect_id
    end)

    %{state | continuous_effects: continuous_effects}
  end
end
