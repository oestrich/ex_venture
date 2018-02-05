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

      iex> Game.Command.Train.parse("train")
      {:error, :bad_parse, "train"}

      iex> Game.Command.Train.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  def parse(command)
  def parse("train list"), do: {:list}
  def parse("train list from " <> name), do: {:list, name}

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
