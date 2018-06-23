defmodule Game.Experience do
  @moduledoc """
  Leveling up a character
  """

  use Networking.Socket

  alias Data.Save
  alias Game.DamageTypes

  @doc """
  Apply experience points to the user's save

  Will echo experience to the socket
  """
  @spec apply(map(), level: integer(), experience_points: integer()) :: {:update, map()}
  def apply(state, level: level, experience_points: exp) do
    exp = calculate_experience(state.save, level, exp)
    save = add_experience(state.save, exp)

    case leveled_up?(state.save, save) do
      true ->
        save = level_up(save)

        {:ok, :level_up, exp, update_state_save(state, save)}

      false ->
        {:ok, exp, update_state_save(state, save)}
    end
  end

  defp update_state_save(state, save) do
    state
    |> Map.put(:user, %{state.user | save: save})
    |> Map.put(:save, save)
  end

  @doc """
  Calculate experience for the player

  This will scale based on how close the user is to the character they beat. Too low
  and they get less experience. Higher levels generate more experience.

      iex> Game.Experience.calculate_experience(%{level: 5}, 5, 100)
      100

  Higher:

      iex> Game.Experience.calculate_experience(%{level: 5}, 6, 100)
      120

      iex> Game.Experience.calculate_experience(%{level: 5}, 7, 100)
      140

      iex> Game.Experience.calculate_experience(%{level: 5}, 12, 100)
      200

  Lower:

      iex> Game.Experience.calculate_experience(%{level: 5}, 4, 100)
      80

      iex> Game.Experience.calculate_experience(%{level: 5}, 3, 100)
      60

      iex> Game.Experience.calculate_experience(%{level: 10}, 3, 100)
      1
  """
  @spec calculate_experience(Save.t(), integer(), integer()) :: integer()
  def calculate_experience(save, level, exp)

  def calculate_experience(%{level: player_level}, level, exp) do
    case level - player_level do
      diff when diff > 0 ->
        multiplier = 1 + diff * 0.2
        min(round(exp * multiplier), exp * 2)

      diff when diff < 0 ->
        multiplier = 1 + diff * 0.2
        max(round(exp * multiplier), 1)

      _ ->
        exp
    end
  end

  @doc """
  Add experience to a user's save

      iex> Game.Experience.add_experience(%{experience_points: 100}, 100)
      %{experience_points: 200}
  """
  @spec add_experience(Save.t(), integer()) :: Save.t()
  def add_experience(save = %{experience_points: current_xp}, experience_points) do
    Map.put(save, :experience_points, current_xp + experience_points)
  end

  @doc """
  Check for a level up

      iex> Game.Experience.leveled_up?(%{experience_points: 900}, %{experience_points: 1000})
      true

      iex> Game.Experience.leveled_up?(%{experience_points: 1900}, %{experience_points: 2001})
      true

      iex> Game.Experience.leveled_up?(%{experience_points: 1001}, %{experience_points: 1100})
      false

      iex> Game.Experience.leveled_up?(%{experience_points: 1501}, %{experience_points: 1700})
      false
  """
  @spec leveled_up?(Save.t(), Save.t()) :: boolean()
  def leveled_up?(start_save, save)

  def leveled_up?(%{experience_points: starting_xp}, %{experience_points: finishing_xp}) do
    div(starting_xp, 1000) < div(finishing_xp, 1000)
  end

  @doc """
  Level a save if required
  """
  @spec maybe_level_up(Save.t(), Save.t()) :: Save.t()
  def maybe_level_up(start_save, save) do
    case leveled_up?(start_save, save) do
      true ->
        level_up(save)

      false ->
        save
    end
  end

  @doc """
  Level up after receing experience points

      iex> Game.Experience.level_up(%{level: 1, experience_points: 1000, stats: %{}})
      %{level: 2, level_stats: %{}, experience_points: 1000, stats: %{}}

      iex> Game.Experience.level_up(%{level: 10, experience_points: 10030, stats: %{}})
      %{level: 11, level_stats: %{}, experience_points: 10030, stats: %{}}
  """
  @spec level_up(Save.t()) :: Save.t()
  def level_up(save = %{experience_points: xp}) do
    level = div(xp, 1000) + 1

    stats =
      save.stats
      |> Enum.reduce(%{}, fn {key, val}, stats ->
        Map.put(stats, key, val + stat_boost_on_level(save.level_stats, key))
      end)

    save
    |> Map.put(:level, level)
    |> Map.put(:level_stats, %{})
    |> Map.put(:stats, stats)
  end

  @doc """
  Calculate the increase of a stat each level

      iex> Game.Experience.stat_boost_on_level(%{}, :health_points)
      5

      iex> Game.Experience.stat_boost_on_level(%{}, :max_health_points)
      5

      iex> Game.Experience.stat_boost_on_level(%{}, :skill_points)
      5

      iex> Game.Experience.stat_boost_on_level(%{}, :max_skill_points)
      5

      iex> Game.Experience.stat_boost_on_level(%{}, :endurance_points)
      5

      iex> Game.Experience.stat_boost_on_level(%{}, :max_endurance_points)
      5

      iex> Game.Experience.stat_boost_on_level(%{}, :strength)
      1

      iex> Game.Experience.stat_boost_on_level(%{}, :agility)
      1

      iex> Game.Experience.stat_boost_on_level(%{}, :vitality)
      1

      iex> Game.Experience.stat_boost_on_level(%{}, :intelligence)
      1

      iex> Game.Experience.stat_boost_on_level(%{}, :awareness)
      1
  """
  @spec stat_boost_on_level(map(), atom()) :: integer()
  def stat_boost_on_level(level_stats, :health_points) do
    5 + health_usage(level_stats)
  end

  def stat_boost_on_level(level_stats, :max_health_points) do
    5 + health_usage(level_stats)
  end

  def stat_boost_on_level(level_stats, :skill_points) do
    5 + skill_usage(level_stats)
  end

  def stat_boost_on_level(level_stats, :max_skill_points) do
    5 + skill_usage(level_stats)
  end

  def stat_boost_on_level(level_stats, :endurance_points) do
    5 + endurance_usage(level_stats)
  end

  def stat_boost_on_level(level_stats, :max_endurance_points) do
    5 + endurance_usage(level_stats)
  end

  def stat_boost_on_level(level_stats, :strength) do
    case :strength in top_stats_used_in_level(level_stats) do
      true -> 2
      false -> 1
    end
  end

  def stat_boost_on_level(level_stats, :agility) do
    case :agility in top_stats_used_in_level(level_stats) do
      true -> 2
      false -> 1
    end
  end

  def stat_boost_on_level(level_stats, :intelligence) do
    case :intelligence in top_stats_used_in_level(level_stats) do
      true -> 2
      false -> 1
    end
  end

  def stat_boost_on_level(level_stats, :awareness) do
    case :awareness in top_stats_used_in_level(level_stats) do
      true -> 2
      false -> 1
    end
  end

  def stat_boost_on_level(level_stats, :vitality) do
    case :vitality in top_stats_used_in_level(level_stats) do
      true -> 2
      false -> 1
    end
  end

  def stat_boost_on_level(level_stats, :willpower) do
    case :willpower in top_stats_used_in_level(level_stats) do
      true -> 2
      false -> 1
    end
  end

  defp health_usage(level_stats) do
    level_stats
    |> Map.take([:strength, :agility])
    |> Map.to_list()
    |> Enum.map(fn {_, count} -> count end)
    |> Enum.sum()
    |> Kernel.*(0.2)
    |> round()
    |> min(10)
  end

  defp skill_usage(level_stats) do
    level_stats
    |> Map.take([:intelligence, :awareness])
    |> Map.to_list()
    |> Enum.map(fn {_, count} -> count end)
    |> Enum.sum()
    |> Kernel.*(0.2)
    |> round()
    |> min(10)
  end

  defp endurance_usage(level_stats) do
    level_stats
    |> Map.take([:vitality, :willpower])
    |> Map.to_list()
    |> Enum.map(fn {_, count} -> count end)
    |> Enum.sum()
    |> Kernel.*(0.2)
    |> round()
    |> min(10)
  end

  defp top_stats_used_in_level(level_stats) do
    level_stats
    |> Map.to_list()
    |> Enum.sort_by(fn {_, val} -> val end)
    |> Enum.reverse()
    |> Enum.take(2)
    |> Enum.map(fn {stat, _} -> stat end)
  end

  @doc """
  Track usage of stats when using skills (or anything with effects)
  """
  @spec track_stat_usage(Save.t(), [Effect.t()]) :: Save.t()
  def track_stat_usage(save, effects) do
    Enum.reduce(effects, save, &_track_stat_usage(&1, &2))
  end

  defp _track_stat_usage(effect = %{kind: "damage"}, save) do
    case DamageTypes.get(effect.type) do
      {:ok, damage_type} ->
        increment_level_stat(save, damage_type.stat_modifier)

      _ ->
        save
    end
  end

  defp _track_stat_usage(effect = %{kind: "damage/over-time"}, save) do
    case DamageTypes.get(effect.type) do
      {:ok, damage_type} ->
        increment_level_stat(save, damage_type.stat_modifier)

      _ ->
        save
    end
  end

  defp _track_stat_usage(%{kind: "recover"}, save) do
    increment_level_stat(save, :awareness)
  end

  defp _track_stat_usage(_, save), do: save

  defp increment_level_stat(save, stat) do
    level_stats =
      save.level_stats
      |> Map.put(stat, Map.get(save.level_stats, stat, 0) + 1)

    %{save | level_stats: level_stats}
  end
end
