defmodule Game.Session.Effects do
  @moduledoc """
  Handle effects on a user
  """

  use Game.Environment
  use Game.Zone
  use Networking.Socket

  require Logger

  alias Game.Character
  alias Game.Effect
  alias Game.Format.Effects, as: FormatEffects
  alias Game.Player
  alias Game.Session.Process

  import Game.Session, only: [echo: 2]
  import Game.Character.Helpers, only: [update_effect_count: 2, is_alive?: 1]

  @doc """
  Apply effects after receiving them from a targeter

  Used from the character callback `{:apply_effects, effects, from, description}`.
  """
  @spec apply([Data.Effect.t()], tuple, String.t(), Map) :: map
  def apply(effects, from, description, state = %{save: save}) do
    {stats, effects, continuous_effects} =
      Character.Effects.apply_effects({:player, state.user}, save.stats, state, effects, from)

    state = Player.update_save(state, %{save | stats: stats})

    state.user |> echo_effects(from, description, effects)
    state.user |> maybe_died(state, from)

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
  def maybe_died(player, state, from)

  def maybe_died(player = %{save: %{stats: %{health_points: health_points}}}, state, from)
      when health_points < 1 do
    player |> maybe_transport_to_graveyard()

    state.save.room_id
    |> @environment.notify({:player, player}, {"character/died", {:player, player}, :character, from})

    :ok
  end

  def maybe_died(_player, _state, _from), do: :ok

  @doc """
  Check if there is a graveyard to teleport to. The zone will have it set
  """
  @spec maybe_transport_to_graveyard(User.t()) :: :ok
  def maybe_transport_to_graveyard(player)

  def maybe_transport_to_graveyard(%{save: %{room_id: room_id}}) do
    {:ok, room} = room_id |> @environment.look()

    case @zone.graveyard(room.zone_id) do
      {:ok, graveyard_id} ->
        send(self(), {:resurrect, graveyard_id})

      {:error, :no_graveyard} ->
        :ok
    end
  end

  @doc """
  Echo effects to the player's session
  """
  def echo_effects(player, from, description, effects) do
    case Character.who(from) == {:player, player.id} do
      true ->
        :ok

      false ->
        description = [description | FormatEffects.effects(effects, {:player, player})]
        echo(self(), description |> Enum.join("\n"))
    end
  end

  @doc """
  Apply a continuous effect to the player
  """
  @spec handle_continuous_effect(State.t(), String.t()) :: State.t()
  def handle_continuous_effect(state, effect_id) do
    case Effect.find_effect(state, effect_id) do
      {:ok, effect} ->
        apply_continuous_effect(state, effect)

      {:error, :not_found} ->
        state
    end
  end

  @doc """
  Apply a continuous effect to the player
  """
  @spec apply_continuous_effect(State.t(), Effect.t()) :: State.t()
  def apply_continuous_effect(state = %{save: save}, {from, effect}) do
    {stats, effects} = Character.Effects.apply_continuous_effect(save.stats, state, effect)

    state = Player.update_save(state, %{save | stats: stats})

    effects_message =
      effects
      |> FormatEffects.effects({:player, state.user})
      |> Enum.join("\n")

    state.socket |> @socket.echo(effects_message)

    state.user |> maybe_died(state, from)
    state |> Process.prompt()

    case is_alive?(state.save) do
      true ->
        state |> update_effect_count({from, effect})

      false ->
        state |> Map.put(:continuous_effects, [])
    end
  end
end
