defmodule Game.Session.Effects do
  @moduledoc """
  Handle effects on a user
  """

  use Game.Room
  use Game.Zone
  use Networking.Socket

  require Logger

  alias Game.Character
  alias Game.Effect
  alias Game.Format
  alias Game.Session.Process

  import Game.Session, only: [echo: 2]
  import Game.Character.Helpers, only: [update_character: 2, update_effect_count: 2, is_alive?: 1]

  @doc """
  Apply effects after receiving them from a targeter

  Used from the character callback `{:apply_effects, effects, from, description}`.
  """
  @spec apply([Data.Effect.t()], tuple, String.t(), Map) :: map
  def apply(effects, from, description, state) do
    %{user: user, save: save} = state

    continuous_effects = effects |> Effect.continuous_effects(from)
    stats = effects |> Effect.apply(save.stats)

    save = Map.put(save, :stats, stats)
    user = Map.put(user, :save, save)
    save.room_id |> update_character(user)
    state = %{state | user: user, save: save}

    user |> echo_effects(from, description, effects)
    user |> maybe_died(state, from)

    Enum.each(continuous_effects, fn {_from, effect} ->
      Logger.debug(fn -> "Delaying effect (#{effect.id})" end, type: :player)
      :erlang.send_after(effect.every, self(), {:continuous_effect, effect.id})
    end)

    case is_alive?(state.save) do
      true ->
        state |> Map.put(:continuous_effects, state.continuous_effects ++ continuous_effects)

      false ->
        state |> Map.put(:continuous_effects, [])
    end
  end

  @doc """
  Check for health < 0 and perform actions if it is
  """
  @spec maybe_died(User.t(), State.t(), Character.t()) :: :ok
  def maybe_died(user, state, from)

  def maybe_died(user = %{save: %{stats: %{health_points: health_points}}}, state, from)
      when health_points < 1 do
    user |> maybe_transport_to_graveyard()

    state.save.room_id
    |> @room.notify({:user, user}, {"character/died", {:user, user}, :character, from})

    :ok
  end

  def maybe_died(_user, _state, _from), do: :ok

  @doc """
  Check if there is a graveyard to teleport to. The zone will have it set
  """
  @spec maybe_transport_to_graveyard(User.t()) :: :ok
  def maybe_transport_to_graveyard(user)

  def maybe_transport_to_graveyard(%{save: %{room_id: room_id}}) do
    room = room_id |> @room.look()

    case @zone.graveyard(room.zone_id) do
      {:ok, graveyard_id} ->
        send(self(), {:resurrect, graveyard_id})

      {:error, :no_graveyard} ->
        :ok
    end
  end

  @doc """
  Echo effects to the user's session
  """
  def echo_effects(user, from, description, effects) do
    user_id = user.id

    case Character.who(from) do
      {:user, ^user_id} ->
        :ok

      _ ->
        description = [description | Format.effects(effects)]
        echo(self(), description |> Enum.join("\n"))
    end
  end

  @doc """
  Apply a continuous effect to the user
  """
  @spec handle_continuous_effect(State.t(), String.t()) :: State.t()
  def handle_continuous_effect(state, effect_id) do
    case Enum.find(state.continuous_effects, fn {_from, effect} -> effect.id == effect_id end) do
      nil -> state
      effect -> apply_continuous_effect(state, effect)
    end
  end

  @doc """
  Apply a continuous effect to the user
  """
  @spec apply_continuous_effect(State.t(), Effect.t()) :: State.t()
  def apply_continuous_effect(state, {from, effect}) do
    %{socket: socket, user: user, save: save} = state

    stats = [effect] |> Effect.apply(save.stats)
    save = Map.put(save, :stats, stats)
    user = Map.put(user, :save, save)
    save.room_id |> update_character(user)
    state = %{state | user: user, save: save}

    socket |> @socket.echo([effect] |> Format.effects() |> Enum.join("\n"))

    user |> maybe_died(state, from)
    state |> Process.prompt()

    case is_alive?(save) do
      true ->
        state |> update_effect_count({from, effect})

      false ->
        state |> Map.put(:continuous_effects, [])
    end
  end
end
