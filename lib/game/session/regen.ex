defmodule Game.Session.Regen do
  @moduledoc """
  Handle a game tick for a player
  """

  use Game.Room

  import Game.Session, only: [echo: 2]
  import Game.Character.Helpers, only: [update_character: 2]

  alias Game.Config
  alias Game.Session.GMCP
  alias Game.Session.State
  alias Game.Stats

  @movement_regen 1

  @doc """
  Maybe trigger a regeneration, if not already regenerating and not at max stats
  """
  @spec maybe_trigger_regen(State.t()) :: State.t()
  def maybe_trigger_regen(state = %{regen: %{is_regenerating: true}}) do
    state
  end

  def maybe_trigger_regen(state) do
    state |> trigger_regen_if_not_max()
  end

  @doc """
  Perform a tick on a session

  - Regen
  """
  @spec tick(map()) :: map()
  def tick(state) do
    state
    |> handle_regen(Config.regen_tick_count(5))
    |> regen_movement()
    |> push(state)
    |> trigger_regen_if_not_max()
  end

  @doc """
  Trigger a regeneration if the stats are not a max
  """
  @spec trigger_regen_if_not_max(State.t()) :: State.t()
  def trigger_regen_if_not_max(state) do
    case hp_max?(state) && sp_max?(state) && mp_max?(state) do
      true ->
        %{state | regen: %{state.regen | is_regenerating: false}}

      false ->
        :erlang.send_after(2000, self(), :regen)
        %{state | regen: %{state.regen | is_regenerating: true}}
    end
  end

  defp hp_max?(%{save: save}) do
    save.stats.health_points == save.stats.max_health_points
  end

  defp sp_max?(%{save: save}) do
    save.stats.skill_points == save.stats.max_skill_points
  end

  defp mp_max?(%{save: save}) do
    save.stats.move_points == save.stats.max_move_points
  end

  @doc """
  Push character vitals to the client on regen

  Only pushes if the stats changed
  """
  @spec push(State.t(), State.t()) :: State.t()
  def push(state = %{save: %{stats: stats}}, %{save: %{stats: stats}}) do
    state
  end

  def push(state, _old_state) do
    state |> GMCP.vitals()
    state
  end

  @doc """
  Regenerate movement points, 1 per tick
  """
  @spec regen_movement(map) :: map
  def regen_movement(state = %{user: user, save: save = %{stats: stats}}) do
    stats = Stats.regen(:move_points, stats, @movement_regen)

    save = Map.put(save, :stats, stats)
    user = Map.put(user, :save, save)
    save.room_id |> update_character(user)

    state
    |> Map.put(:save, save)
  end

  @doc """
  Perform regen if necessary

  Will regen once every n ticks as defined by the game config. Defaults to 5 ticks.
  """
  @spec handle_regen(map, integer) :: map
  def handle_regen(state = %{regen: %{count: count}}, count) do
    %{user: user, save: save} = state

    stats = Stats.regen(:health_points, save.stats, save.level)
    stats = Stats.regen(:skill_points, stats, save.level)

    echo_health(save.stats, stats)

    save = Map.put(save, :stats, stats)
    user = Map.put(user, :save, save)
    save.room_id |> update_character(user)

    state
    |> Map.put(:save, save)
    |> Map.put(:regen, %{state.regen | count: 0})
  end

  def handle_regen(state = %{regen: %{count: count}}, _count) do
    state
    |> Map.put(:regen, %{state.regen | count: count + 1})
  end

  @doc """
  Display regen text to the user
  """
  @spec echo_health(Stats.t(), Stats.t()) :: nil
  def echo_health(starting_stats, stats) do
    starting_hp = starting_stats.health_points
    starting_sp = starting_stats.skill_points

    case stats do
      %{health_points: ^starting_hp, skill_points: ^starting_sp} ->
        nil

      %{health_points: ^starting_hp} ->
        echo(self(), "You regenerated some skill points.")

      %{skill_points: ^starting_sp} ->
        echo(self(), "You regenerated some health points.")

      _ ->
        echo(self(), "You regenerated some health and skill points.")
    end
  end
end
