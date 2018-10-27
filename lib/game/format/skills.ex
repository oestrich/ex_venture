defmodule Game.Format.Skills do
  @moduledoc """
  Format functions for skills
  """

  import Game.Format.Context

  alias Data.Skill
  alias Game.Format
  alias Game.Format.Table

  @doc """
  Format a skill name, white

    iex> Skills.skill_name(%{name: "Slash"})
    "{skill}Slash{/skill}"
  """
  @spec skill_name(Skill.t()) :: String.t()
  def skill_name(skill) do
    "{skill}#{skill.name}{/skill}"
  end

  @doc """
  Format skills
  """
  @spec skills([Skill.t()]) :: String.t()
  def skills(skills)

  def skills(skills) do
    skills =
      skills
      |> Enum.map(&skill(&1))
      |> Enum.join("\n")

    """
    Known Skills
    #{Format.underline("Known Skills")}

    #{skills}
    """
    |> String.trim()
  end

  @doc """
  Format a skill

      iex> skill = %{level: 1, name: "Slash", points: 2, command: "slash", description: "Fight your foe"}
      iex> Skills.skill(skill)
      "{skill}Slash{/skill} - Level 1 - 2sp\\nCommand: {command send='help slash'}slash{/command}\\nFight your foe\\n"
  """
  @spec skill(Skill.t()) :: String.t()
  def skill(skill) do
    """
    {skill}#{skill.name}{/skill} - Level #{skill.level} - #{skill.points}sp
    Command: {command send='help #{skill.command}'}#{skill.command}{/command}
    #{skill.description}
    """
  end

  @doc """
  Format a skill, from perspective of the player

      iex> Skills.skill_user(%{user_text: "Slash away"}, {:player, %{name: "Player"}}, {:npc, %{name: "Bandit"}})
      "Slash away"

      iex> Skills.skill_user(%{user_text: "You slash away at [target]"}, {:player, %{name: "Player"}}, {:npc, %{name: "Bandit"}})
      "You slash away at {npc}Bandit{/npc}"
  """
  def skill_user(skill, player, target)

  def skill_user(%{user_text: user_text}, player, target) do
    context()
    |> assign(:user, Format.target_name(player))
    |> assign(:target, Format.target_name(target))
    |> Format.template(user_text)
  end

  @doc """
  Format a skill, from the perspective of a usee

      iex> Skills.skill_usee(%{usee_text: "Slash away"}, user: {:npc, %{name: "Bandit"}}, target: {:npc, %{name: "Bandit"}})
      "Slash away"

      iex> Skills.skill_usee(%{usee_text: "You were slashed at by [user]"}, user: {:npc, %{name: "Bandit"}}, target: {:player, %{name: "Player"}})
      "You were slashed at by {npc}Bandit{/npc}"
  """
  def skill_usee(skill, opts \\ [])

  def skill_usee(%{usee_text: usee_text}, opts) do
    skill_usee(usee_text, opts)
  end

  def skill_usee(usee_text, opts) do
    context()
    |> assign(:user, Format.target_name(Keyword.get(opts, :user)))
    |> assign(:target, Format.target_name(Keyword.get(opts, :target)))
    |> Format.template(usee_text)
  end

  @doc """
  List out skills that a trainer will give
  """
  @spec trainable_skills(NPC.t(), [Skill.t()]) :: String.t()
  def trainable_skills(trainer, skills) do
    rows =
      skills
      |> Enum.map(fn {skill, cost} ->
        [to_string(skill.id), skill.name, skill.command, cost]
      end)

    rows = [["ID", "Name", "Command", "Cost"] | rows]

    Table.format("#{Format.npc_name(trainer)} will train these skills:", rows, [5, 30, 20, 10])
  end
end
