defmodule Game.Session.Tick do
  @moduledoc """
  Handle a game tick for a player
  """

  use Game.Room

  import Game.Session, only: [echo: 2]
  import Game.Character.Update, only: [update_character: 2]

  alias Game.Config
  alias Game.Stats

  @movement_regen 1

  @doc """
  Perform a tick on a session

  - Regen
  - Save last tick timestamp
  """
  @spec tick(time :: DateTime.t, state :: Map) :: map
  def tick(time, state) do
    state
    |> handle_regen(Config.regen_tick_count(5))
    |> regen_movement()
    |> Map.put(:last_tick, time)
  end

  @doc """
  Regenerate movement points, 1 per tick
  """
  @spec regen_movement(state :: map) :: map
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
  @spec handle_regen(state :: map, count :: integer) :: map
  def handle_regen(state = %{regen: %{count: count}, user: user = %{class: class}, save: save}, count) do
    stats = Stats.regen(:health, save.stats, class.regen_health)
    stats = Stats.regen(:skill_points, stats, class.regen_skill_points)

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
  @spec echo_health(starting_stats :: Stats.t, stats :: Stats.t, class :: Class.t) :: nil
  def echo_health(starting_stats, stats, class) do
    starting_hp = starting_stats.health
    starting_sp = starting_stats.skill_points

    case stats do
      %{health: ^starting_hp, skill_points: ^starting_sp} ->
        nil
      %{health: ^starting_hp} ->
        echo(self(), "You regenerated some #{class.points_name |> String.downcase}.")
      %{skill_points: ^starting_sp} -> nil
        echo(self(), "You regenerated some health.")
      _ ->
        echo(self(), "You regenerated some health and #{class.points_name |> String.downcase}.")
    end
  end
end
