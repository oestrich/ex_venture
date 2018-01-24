defmodule Game.Skill do
  @moduledoc """
  Game side of skills

  Skill cost, etc
  """

  @doc """
  Pay for a skill

      iex> Game.Skill.pay(%{skill_points: 10}, %{points: 3})
      {:ok, %{skill_points: 7}}

      iex> Game.Skill.pay(%{skill_points: 3}, %{points: 3})
      {:ok, %{skill_points: 0}}

      iex> Game.Skill.pay(%{skill_points: 2}, %{points: 3})
      {:error, :not_enough_points}
  """
  def pay(stats, skill)

  def pay(stats, skill) do
    stats = %{stats | skill_points: stats.skill_points - skill.points}

    case stats do
      %{skill_points: points} when points < 0 ->
        {:error, :not_enough_points}

      _ ->
        {:ok, stats}
    end
  end
end
