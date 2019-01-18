defmodule Game.Command.Train do
  @moduledoc """
  The "emote" command
  """

  use Game.Command

  alias Data.ActionBar
  alias Game.Format.Skills, as: FormatSkills
  alias Game.Player
  alias Game.Session.GMCP
  alias Game.Skill
  alias Game.Skills
  alias Game.Utility

  commands(["train"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Train"
  def help(:short), do: "Train skills from NPCs"

  def help(:full) do
    """
    Train skills from NPCs. You can train new skills from NPCs around the world.

    If you find an NPC that trains skills, you can list available skills with:
    [ ] > {command}train list{/command}

    If there are multiple trainers in the same room, specify the NPC
    [ ] > {command}train list from guard{/command}

    Once you pick a skill to train, train it with:
    [ ] > {command}train skill{/command}

    If there are multiple trainers in the same room, specify the NPC
    [ ] > {command}train skill from guard{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Train.parse("train list")
      {:list}

      iex> Game.Command.Train.parse("train list from guard")
      {:list, "guard"}

      iex> Game.Command.Train.parse("train skill")
      {:train, "skill"}

      iex> Game.Command.Train.parse("train skill from guard")
      {:train, "skill", :from, "guard"}

      iex> Game.Command.Train.parse("train")
      {:error, :bad_parse, "train"}

      iex> Game.Command.Train.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  def parse(command)
  def parse("train list"), do: {:list}
  def parse("train list from " <> name), do: {:list, name}
  def parse("train " <> string), do: parse_train_command(string)

  @doc """
  Find skill name and the trainer
  """
  @spec parse_train_command(String.t()) :: :ok
  def parse_train_command(string) do
    case Regex.run(~r/(?<skill>.+) from (?<shop>.+)/i, string, capture: :all) do
      nil ->
        {:train, string}

      [_string, skill_name, shop_name] ->
        {:train, skill_name, :from, shop_name}
    end
  end

  @impl Game.Command
  @doc """
  Perform an emote
  """
  def run(command, state)

  def run({:list}, state = %{save: save}) do
    {:ok, room} = Environment.look(save.room_id)

    case one_trainer(room.npcs) do
      {:ok, trainer} ->
        skills =
          trainer.extra.trainable_skills
          |> Skills.skills()
          |> filter_player_skills(save)
          |> filter_skills_by_level(save)
          |> add_skill_cost(save)

        skill_table = FormatSkills.trainable_skills(trainer, skills)
        spent_experience_points = save.experience_points - save.spent_experience_points

        message = gettext("You have %{xp} XP to spend.", xp: spent_experience_points)
        message = "#{message}\n#{skill_table}"
        state |> Socket.echo(message)

      {:error, :more_than_one_trainer} ->
        message = gettext("There are more than one trainer in this room. Please refer by name.")
        state |> Socket.echo(message)

      {:error, :not_found} ->
        message = gettext("There are no trainers in this room. Go find some!")
        state |> Socket.echo(message)
    end
  end

  def run({:list, name}, state = %{save: save}) do
    {:ok, room} = Environment.look(save.room_id)

    case find_trainer(room.npcs, name) do
      {:ok, trainer} ->
        skills = Skills.skills(trainer.extra.trainable_skills)
        state |> Socket.echo(FormatSkills.trainable_skills(trainer, skills))

      {:error, :not_found} ->
        message = gettext("There are no trainers by that name in this room. Go find them!")
        state |> Socket.echo(message)
    end
  end

  def run({:train, skill_name}, state = %{save: save}) do
    {:ok, room} = Environment.look(save.room_id)

    case one_trainer(room.npcs) do
      {:ok, trainer} ->
        trainer |> maybe_train_skill(skill_name, state)

      {:error, :more_than_one_trainer} ->
        message = gettext("There are more than one trainer in this room. Please refer by name.")
        state |> Socket.echo(message)

      {:error, :not_found} ->
        message = gettext("There are no trainers in this room. Go find some!")
        state |> Socket.echo(message)
    end
  end

  def run({:train, skill_name, :from, npc_name}, state = %{save: save}) do
    {:ok, room} = Environment.look(save.room_id)

    case find_trainer(room.npcs, npc_name) do
      {:ok, trainer} ->
        trainer |> maybe_train_skill(skill_name, state)

      {:error, :not_found} ->
        message = gettext("There are no trainers by that name in this room. Go find them!")
        state |> Socket.echo(message)
    end
  end

  defp maybe_train_skill(trainer, skill_name, state) do
    trainer
    |> find_skill(skill_name, state)
    |> check_if_skill_known(state)
    |> check_if_right_level(state)
    |> check_if_enough_experience_to_spend(state)
    |> train_skill(state)
  end

  defp find_skill(trainer, skill_name, state) do
    skill =
      trainer.extra.trainable_skills
      |> Skills.skills()
      |> Enum.find(&Utility.matches?(&1, skill_name))

    case skill do
      nil ->
        message = gettext("Could not find skill \"%{name}\".", name: skill_name)
        state |> Socket.echo(message)

      skill ->
        skill
    end
  end

  defp check_if_skill_known(:ok, _state), do: :ok

  defp check_if_skill_known(skill, state = %{save: save}) do
    case Enum.member?(save.skill_ids, skill.id) do
      true ->
        message = gettext("%{name} is already known.", name: skill.name)
        state |> Socket.echo(message)

      false ->
        skill
    end
  end

  defp check_if_right_level(:ok, _state), do: :ok

  defp check_if_right_level(skill, state = %{save: save}) do
    case skill.level > save.level do
      true ->
        message =
          gettext("You are not ready to learn %{name}. Go experience the world more.",
            name: skill.name
          )

        state |> Socket.echo(message)

      false ->
        skill
    end
  end

  defp check_if_enough_experience_to_spend(:ok, _state), do: :ok

  defp check_if_enough_experience_to_spend(skill, state = %{save: save}) do
    skill_cost = Skill.skill_train_cost(skill, save)
    spendable_experience = save.experience_points - save.spent_experience_points

    case skill_cost <= spendable_experience do
      true ->
        skill

      false ->
        message =
          gettext("You do not have enough experience to spend to train %{name}.", name: skill.name)

        state |> Socket.echo(message)
    end
  end

  defp train_skill(:ok, _state), do: :ok

  defp train_skill(skill, state = %{save: save}) do
    skill_cost = Skill.skill_train_cost(skill, save)

    message =
      gettext("%{name} trained successfully! %{cost} XP spent.",
        name: skill.name,
        cost: skill_cost
      )

    state |> Socket.echo(message)

    skill_ids = Enum.uniq([skill.id | save.skill_ids])
    spent_experience_points = save.spent_experience_points + skill_cost

    save = %{save | skill_ids: skill_ids, spent_experience_points: spent_experience_points}
    save = ActionBar.maybe_add_action(save, %ActionBar.SkillAction{id: skill.id})
    state = Player.update_save(state, save)

    state |> GMCP.character_skills()
    state |> GMCP.config_actions()

    {:update, state}
  end

  defp one_trainer(npcs) do
    case npcs |> Enum.filter(& &1.extra.is_trainer) do
      [trainer] ->
        {:ok, trainer}

      [_ | _tail] ->
        {:error, :more_than_one_trainer}

      _ ->
        {:error, :not_found}
    end
  end

  defp find_trainer(npcs, name) do
    case Enum.find(npcs, fn npc -> Utility.matches?(npc, name) end) do
      nil ->
        {:error, :not_found}

      npc ->
        {:ok, npc}
    end
  end

  defp filter_player_skills(skills, save) do
    Enum.reject(skills, fn skill ->
      Enum.member?(save.skill_ids, skill.id)
    end)
  end

  defp filter_skills_by_level(skills, save) do
    Enum.reject(skills, fn skill ->
      skill.level > save.level
    end)
  end

  defp add_skill_cost(skills, save) do
    Enum.map(skills, fn skill ->
      {skill, Skill.skill_train_cost(skill, save)}
    end)
  end
end
