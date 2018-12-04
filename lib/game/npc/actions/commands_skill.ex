defmodule Game.NPC.Actions.CommandsSkill do
  @moduledoc """
  Use a skill on the NPC's target
  """

  use Game.Environment

  import Game.Command.Skills, only: [find_target: 2]

  alias Game.Character
  alias Game.Effect
  alias Game.Format.Skills, as: FormatSkills
  alias Game.Skill
  alias Game.Skills

  def act(state, action) do
    with {:ok, room} <- look_room(state),
         {:ok, target} <- get_target(state, room),
         {:ok, skill} <- get_skill(action.options),
         {:ok, effects} <- calculate_effects(state, skill) do
      npc = {:npc, state.npc}
      skill_text = FormatSkills.skill_usee(skill, user: npc, target: target)
      Character.apply_effects(target, effects, npc, skill_text)

      {:ok, state}
    else
      _ ->
        {:ok, state}
    end
  end

  defp look_room(state) do
    @environment.look(state.room_id)
  end

  defp get_target(state, room) do
    case state.target do
      nil ->
        {:error, :no_target}

      target ->
        find_target(room, Character.who(target))
    end
  end

  defp get_skill(options) do
    case Skills.skill(options.skill) do
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
