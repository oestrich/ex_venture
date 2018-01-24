defmodule Game.Session.Tick do
  @moduledoc """
  Handle a game tick for a player
  """

  use Game.Room

  import Game.Session, only: [echo: 2]
  import Game.Character.Helpers, only: [update_character: 2]

  alias Game.Config
  alias Game.Session.GMCP
  alias Game.Stats

  @movement_regen 1

  @doc """
  Perform a tick on a session

  - Regen
  - Save last tick timestamp
  """
  @spec tick(DateTime.t(), Map) :: map
  def tick(time, state) do
    state
    |> handle_regen(Config.regen_tick_count(5))
    |> regen_movement()
    |> push(state)
    |> Map.put(:last_tick, time)
  end

  @doc """
  Push character vitals to the client on regen

  Only pushes if the stats changed
  """
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
    %{user: user = %{class: class}, save: save} = state
    stats = Stats.regen(:health, save.stats, class.regen_health * save.level)
    stats = Stats.regen(:skill_points, stats, class.regen_skill_points * save.level)

    echo_health(save.stats, stats, class)

    save = Map.put(save, :stats, stats)
    user = Map.put(user, :save, save)
    save.room_id |> update_character(user)

    state
    |> Map.put(:save, save)
    |> Map.put(:regen, %{count: 0})
  end

  def handle_regen(state = %{regen: %{count: count}}, _count) do
    state
    |> Map.put(:regen, %{count: count + 1})
  end

  @doc """
  Display regen text to the user
  """
  @spec echo_health(Stats.t(), Stats.t(), Class.t()) :: nil
  def echo_health(starting_stats, stats, class) do
    starting_hp = starting_stats.health
    starting_sp = starting_stats.skill_points

    case stats do
      %{health: ^starting_hp, skill_points: ^starting_sp} ->
        nil

      %{health: ^starting_hp} ->
        echo(self(), "You regenerated some #{class.points_name |> String.downcase()}.")

      %{skill_points: ^starting_sp} ->
        nil
        echo(self(), "You regenerated some health.")

      _ ->
        echo(self(), "You regenerated some health and #{class.points_name |> String.downcase()}.")
    end
  end
end
