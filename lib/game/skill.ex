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

  @doc """
  Calculate the training cost (in experience) of a skill

      iex> Game.Skill.skill_train_cost(%{level: 3}, %{level: 3})
      1000

      iex> Game.Skill.skill_train_cost(%{level: 3}, %{level: 4})
      900

      iex> Game.Skill.skill_train_cost(%{level: 3}, %{level: 13})
      100
  """
  def skill_train_cost(skill, save) do
    cost = 1000 - 100 * (save.level - skill.level)
    Enum.max([cost, 100])
  end

  @doc """
  Filter out effects that don't match the skill's whitelist
  """
  @spec filter_effects([Effect.t()], Skill.t()) :: [Effect.t()]
  def filter_effects(effects, skill) do
    Enum.filter(effects, fn effect ->
      effect.kind in skill.white_list_effects
    end)
  end
end
