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
    context()
    |> assign(:name, skill.name)
    |> Format.template("{skill}[name]{/skill}")
  end

  @doc """
  Format skills
  """
  @spec skills([Skill.t()]) :: String.t()
  def skills(skills)

  def skills(skills) do
    context()
    |> assign(:underline, Format.underline("Known Skills"))
    |> assign_many(:skills, skills, &skill/1)
    |> Format.template("Known Skills\n[underline]\n\n[skills]")
  end

  @doc """
  Format a skill
  """
  @spec skill(Skill.t()) :: String.t()
  def skill(skill) do
    context()
    |> assign(:name, skill_name(skill))
    |> assign(:level, skill.level)
    |> assign(:points, skill.points)
    |> assign(:command, skill.command)
    |> assign(:description, skill.description)
    |> Format.template(template("skill"))
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

  def template("skill") do
    """
    [name] - Level [level] - [points] sp
    Command: {command send='help [command]'}[command]{/command}
    [description]
    """
  end
end
