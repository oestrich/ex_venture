defmodule Game.Stats do
  @moduledoc """
  Regen stats during ticks
  """

  alias Data.Stats

  @doc """
  Regen statistics (hp/sp) every few ticks

    iex> Game.Stats.regen(:health, %{health: 10, max_health: 15}, 3)
    %{health: 13, max_health: 15}

    iex> Game.Stats.regen(:health, %{health: 13, max_health: 15}, 3)
    %{health: 15, max_health: 15}

    iex> Game.Stats.regen(:skill_points, %{skill_points: 10, max_skill_points: 15}, 3)
    %{skill_points: 13, max_skill_points: 15}

    iex> Game.Stats.regen(:skill_points, %{skill_points: 13, max_skill_points: 15}, 3)
    %{skill_points: 15, max_skill_points: 15}

    iex> Game.Stats.regen(:move_points, %{move_points: 10, max_move_points: 15}, 3)
    %{move_points: 13, max_move_points: 15}

    iex> Game.Stats.regen(:move_points, %{move_points: 13, max_move_points: 15}, 3)
    %{move_points: 15, max_move_points: 15}
  """
  @spec regen(field :: atom, stats :: Stats.t, regen :: map) :: Stats.t
  def regen(field, stats, regen)
  def regen(:health, stats, health) do
    case %{stats | health: stats.health + health} do
      %{health: health, max_health: max_health} when health > max_health ->
        %{stats | health: max_health}
      stats -> stats
    end
  end
  def regen(:skill_points, stats, skill_points) do
    case %{stats | skill_points: stats.skill_points + skill_points} do
      %{skill_points: skill_points, max_skill_points: max_skill_points} when skill_points > max_skill_points ->
        %{stats | skill_points: max_skill_points}
      stats -> stats
    end
  end
  def regen(:move_points, stats, move_points) do
    case %{stats | move_points: stats.move_points + move_points} do
      %{move_points: move_points, max_move_points: max_move_points} when move_points > max_move_points ->
        %{stats | move_points: max_move_points}
      stats -> stats
    end
  end
end
