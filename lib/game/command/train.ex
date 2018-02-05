defmodule Game.Command.Train do
  @moduledoc """
  The "emote" command
  """

  use Game.Command

  alias Game.Skills
  alias Game.Utility

  commands(["train"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Train"
  def help(:short), do: "Train skills from NPCs"

  def help(:full) do
    """
    #{help(:short)}.

    Example:
    [ ] > {white}train list{/white}
    """
  end

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
      nil -> {:train, string}
      [_string, skill_name, shop_name] -> {:train, skill_name, :from, shop_name}
    end
  end

  @impl Game.Command
  @doc """
  Perform an emote
  """
  def run(command, state)

  def run({:list}, state = %{save: save}) do
    room = @room.look(save.room_id)

    case one_trainer(room.npcs) do
      {:ok, trainer} ->
        skills =
          trainer.trainable_skills
          |> Skills.skills()
          |> filter_player_skills(save)

        state.socket |> @socket.echo(Format.trainable_skills(trainer, skills))
      {:error, :more_than_one_trainer} ->
        state.socket |> @socket.echo("There are more than one trainer in this room. Please refer by name")
      {:error, :not_found} ->
        state.socket |> @socket.echo("There are no trainers in this room. Go find some!")
    end

    :ok
  end

  def run({:list, name}, state = %{save: save}) do
    room = @room.look(save.room_id)

    case find_trainer(room.npcs, name) do
      {:ok, trainer} ->
        skills = Skills.skills(trainer.trainable_skills)
        state.socket |> @socket.echo(Format.trainable_skills(trainer, skills))
      {:error, :not_found} ->
        state.socket |> @socket.echo("There are no trainers by that name in this room. Go find them!")
    end

    :ok
  end

  def run({:train, skill_name}, state = %{save: save}) do
    room = @room.look(save.room_id)

    case one_trainer(room.npcs) do
      {:ok, trainer} ->
        trainer |> maybe_train_skill(skill_name, state)

      {:error, :more_than_one_trainer} ->
        state.socket |> @socket.echo("There are more than one trainer in this room. Please refer by name")
        :ok

      {:error, :not_found} ->
        state.socket |> @socket.echo("There are no trainers in this room. Go find some!")
        :ok
    end
  end

  def run({:train, skill_name, :from, npc_name}, state = %{save: save}) do
    room = @room.look(save.room_id)

    case find_trainer(room.npcs, npc_name) do
      {:ok, trainer} ->
        trainer |> maybe_train_skill(skill_name, state)

      {:error, :not_found} ->
        state.socket |> @socket.echo("There are no trainers by that name in this room. Go find them!")
        :ok
    end
  end

  defp maybe_train_skill(trainer, skill_name, state) do
    trainer
    |> find_skill(skill_name, state)
    |> check_if_skill_known(state)
    |> train_skill(state)
  end

  defp find_skill(trainer, skill_name, state) do
    skill =
      trainer.trainable_skills
      |> Skills.skills()
      |> Enum.find(&Utility.matches?(&1, skill_name))

    case skill do
      nil ->
        state.socket |> @socket.echo("Could not find skill \"#{skill_name}\"")
        :ok

      skill ->
        skill
    end
  end

  defp check_if_skill_known(:ok, _state), do: :ok
  defp check_if_skill_known(skill, state = %{save: save}) do
    case Enum.member?(save.skill_ids, skill.id) do
      true ->
        state.socket |> @socket.echo("#{skill.name} is already known.")
      false ->
        skill
    end
  end

  defp train_skill(:ok, _state), do: :ok
  defp train_skill(skill, state = %{user: user, save: save}) do
    state.socket |> @socket.echo("#{skill.name} trained successfully!")

    skill_ids = Enum.uniq([skill.id | save.skill_ids])

    save = %{save | skill_ids: skill_ids}
    user = %{user | save: save}
    state = %{state | user: user, save: save}

    {:update, state}
  end

  defp one_trainer(npcs) do
    case npcs |> Enum.filter(& &1.is_trainer) do
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
      nil -> {:error, :not_found}
      npc -> {:ok, npc}
    end
  end

  defp filter_player_skills(skills, save) do
    Enum.reject(skills, fn skill ->
      Enum.member?(save.skill_ids, skill.id)
    end)
  end
end
