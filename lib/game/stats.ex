defmodule Game.Stats do
  @moduledoc """
  Regen stats during ticks
  """

  alias Data.Stats

  @doc """
  Regen statistics (hp/sp) every few ticks

    iex> Game.Stats.regen(%{health_points: 10, max_health_points: 15}, :health_points, 3)
    %{health_points: 13, max_health_points: 15}

    iex> Game.Stats.regen(%{health_points: 13, max_health_points: 15}, :health_points, 3)
    %{health_points: 15, max_health_points: 15}

    iex> Game.Stats.regen(%{skill_points: 10, max_skill_points: 15}, :skill_points, 3)
    %{skill_points: 13, max_skill_points: 15}

    iex> Game.Stats.regen(%{skill_points: 13, max_skill_points: 15}, :skill_points, 3)
    %{skill_points: 15, max_skill_points: 15}

    iex> Game.Stats.regen(%{endurance_points: 10, max_endurance_points: 15}, :endurance_points, 3)
    %{endurance_points: 13, max_endurance_points: 15}

    iex> Game.Stats.regen(%{endurance_points: 13, max_endurance_points: 15}, :endurance_points, 3)
    %{endurance_points: 15, max_endurance_points: 15}
  """
  @spec regen(atom, Stats.t(), map) :: Stats.t()
  def regen(stats, field, regen)

  def regen(stats, :health_points, health_points) do
    case %{stats | health_points: stats.health_points + health_points} do
      %{health_points: health_points, max_health_points: max_health_points}
      when health_points > max_health_points ->
        %{stats | health_points: max_health_points}

      stats ->
        stats
    end
  end

  def regen(stats, :skill_points, skill_points) do
    case %{stats | skill_points: stats.skill_points + skill_points} do
      %{skill_points: skill_points, max_skill_points: max_skill_points}
      when skill_points > max_skill_points ->
        %{stats | skill_points: max_skill_points}

      stats ->
        stats
    end
  end

  def regen(stats, :endurance_points, endurance_points) do
    case %{stats | endurance_points: stats.endurance_points + endurance_points} do
      %{endurance_points: endurance_points, max_endurance_points: max_endurance_points}
      when endurance_points > max_endurance_points ->
        %{stats | endurance_points: max_endurance_points}

      stats ->
        stats
    end
  end
end
