defmodule Game.Character.Helpers do
  @moduledoc """
  Character helper module, common character functions
  """

  use Game.Environment

  alias Data.Effect

  @doc """
  Update the effect count. If the effect count is 0, remove it from the states continuous effects list
  """
  @spec update_effect_count(map(), {Character.t(), Effect.t()}) :: map()
  def update_effect_count(state, {from, effect}) do
    continuous_effects = List.delete(state.continuous_effects, {from, effect})
    effect = %{effect | count: effect.count - 1}
    maybe_send_continuous_effect(effect)

    case effect.count do
      0 ->
        %{state | continuous_effects: continuous_effects}

      _ ->
        %{state | continuous_effects: [{from, effect} | continuous_effects]}
    end
  end

  @doc """
  Maybe send a continuous effect message, only if count is > 0
  """
  @spec maybe_send_continuous_effect(Effect.t()) :: :ok
  def maybe_send_continuous_effect(effect)

  def maybe_send_continuous_effect(%{id: id, every: every, count: count}) when count > 0 do
    :erlang.send_after(every, self(), {:continuous_effect, id})
  end

  def maybe_send_continuous_effect(_), do: :ok

  @doc """
  Determine if the Character is alive still

      iex> Game.Character.Helpers.is_alive?(%{stats: %{health_points: 10}})
      true

      iex> Game.Character.Helpers.is_alive?(%{stats: %{health_points: -1}})
      false
  """
  @spec is_alive?(map()) :: boolean()
  def is_alive?(save)
  def is_alive?(%{stats: %{health_points: health_points}}) when health_points > 0, do: true
  def is_alive?(_), do: false
end
