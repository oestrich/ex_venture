defmodule Game.NPC.Actions.CommandsSkill do
  @moduledoc """
  Use a skill on the NPC's target
  """

  alias Game.Character
  alias Game.Command.Skills, as: CommandSkills
  alias Game.Effect
  alias Game.Environment
  alias Game.Format.Skills, as: FormatSkills
  alias Game.Skill
  alias Game.Skills

  def act(state, action) do
    with {:ok, room} <- look_room(state),
         {:ok, target} <- get_target(state, room),
         {:ok, skill} <- get_skill(action.options),
         {:ok, effects} <- calculate_effects(state, skill) do
      npc = Character.to_simple(state.npc)
      skill_text = FormatSkills.skill_usee(skill, user: npc, target: target)
      Character.apply_effects(target, effects, npc, skill_text)

      {:ok, state}
    else
      {:error, :no_target} ->
        {:ok, %{state | combat: false}}

      _ ->
        {:ok, state}
    end
  end

  defp look_room(state) do
    Environment.look(state.room_id)
  end

  defp get_target(state, room) do
    case state.target do
      nil ->
        {:error, :no_target}

      target ->
        find_target(room, target)
    end
  end

  defp find_target(room, target) do
    case CommandSkills.find_target(room, target) do
      {:ok, target} ->
        {:ok, target}

      {:error, :not_found} ->
        {:error, :no_target}
    end
  end

  defp get_skill(options) do
    skill = Map.get(options, :skill) || ""

    case Skills.skill(skill) do
      nil ->
        {:error, :not_found}

      skill ->
        {:ok, skill}
    end
  end

  def calculate_effects(state, skill) do
    effects = Skill.filter_effects(skill.effects, skill)

    effects =
      state.npc.stats
      |> Effect.calculate_stats_from_continuous_effects(state)
      |> Effect.calculate(effects)

    {:ok, effects}
  end
end
