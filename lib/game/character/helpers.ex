defmodule Game.Character.Helpers do
  @moduledoc """
  Character helper module, common character functions
  """

  use Game.Room

  alias Game.Character
  alias Game.Session
  alias Game.Session.GMCP

  @doc """
  If the state has a target, send the target a removal message.
  """
  @spec clear_target(state :: Session.t(), who :: {atom, map}) :: :ok
  def clear_target(state, who)
  def clear_target(%{target: target}, who = {:npc, _}) when target != nil do
    Character.remove_target(target, who)
  end
  def clear_target(state = %{target: target}, who) when target != nil do
    state |> GMCP.clear_target()
    Character.remove_target(target, who)
  end
  def clear_target(_state, _who), do: :ok

  @doc """
  Update a character's stats in the room
  """
  @spec update_character(room_id :: integer, user :: User.t) :: :ok
  def update_character(room_id, user) do
    room_id |> @room.update_character({:user, user})
  end

  @doc """
  Update the effect count. If the effect count is 0, remove it from the states continuous effects list
  """
  @spec update_effect_count(map(), Effect.t) :: map()
  def update_effect_count(state, effect) do
    continuous_effects = List.delete(state.continuous_effects, effect)
    effect = %{effect | count: effect.count - 1}
    maybe_send_continuous_effect(effect)
    case effect.count do
      0 -> %{state | continuous_effects: continuous_effects}
      _ -> %{state | continuous_effects: [effect | continuous_effects]}
    end
  end

  @doc """
  Maybe send a continuous effect message, only if count is > 0
  """
  @spec maybe_send_continuous_effect(Effect.t) :: :ok
  def maybe_send_continuous_effect(effect)
  def maybe_send_continuous_effect(%{id: id, every: every, count: count}) when count > 0 do
    :erlang.send_after(every, self(), {:continuous_effect, id})
  end
  def maybe_send_continuous_effect(_), do: :ok

  @doc """
  Determine if the Character is alive still

      iex> Game.Character.Helpers.is_alive?(%{stats: %{health: 10}})
      true

      iex> Game.Character.Helpers.is_alive?(%{stats: %{health: -1}})
      false
  """
  @spec is_alive?(map()) :: boolean()
  def is_alive?(save)
  def is_alive?(%{stats: %{health: health}}) when health > 0, do: true
  def is_alive?(_), do: false
end
