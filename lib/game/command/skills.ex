defmodule Game.Command.Skills do
  @moduledoc """
  Parse out class skills
  """

  use Game.Command

  alias Game.Character
  alias Game.Command
  alias Game.Command.Target
  alias Game.Effect
  alias Game.Experience
  alias Game.Hint
  alias Game.Item
  alias Game.Session.GMCP
  alias Game.Skill
  alias Game.Skills

  @must_be_alive true

  commands(["skills"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Skills"
  def help(:short), do: "List out your class skills"

  def help(:full) do
    """
    #{help(:short)}. To use a skill you must also be
    targeting something. Optionally pass in a target after your skill to switch or set
    a target before using a skill.

    Example:
    [ ] > {command}skills{/command}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Skills.parse("skills")
      {}

      iex> Game.Command.Skills.parse("skills all")
      {:all}

      iex> Game.Command.Skills.parse("skills hi")
      {:error, :bad_parse, "skills hi"}

      iex> Game.Command.Skills.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  def parse(command)
  def parse("skills"), do: {}
  def parse("skills all"), do: {:all}

  @doc """
  Parse skill specific commands
  """
  @spec parse_skill(String.t(), User.t()) :: Command.t() | {:error, :bad_parse, String.t()}
  def parse_skill(command, user)

  def parse_skill(command, %{save: save}) do
    with {:ok, skill} <- parse_find_skill(command),
         {:ok, skill} <- parse_check_skill_known(skill, save),
         {:ok, skill} <- parse_check_skill_level(skill, save) do
      %Command{text: command, module: __MODULE__, args: {skill, command}}
    else
      {:error, :not_found} ->
        {:error, :bad_parse, command}

      {:error, :not_known, skill} ->
        %Command{text: command, module: __MODULE__, args: {skill, :not_known}}

      {:error, :level_too_low, skill} ->
        %Command{text: command, module: __MODULE__, args: {skill, :level_too_low}}
    end
  end

  defp parse_find_skill(command) do
    skill =
      Skills.all()
      |> Enum.find(fn skill ->
        Regex.match?(~r(^#{skill.command}), command)
      end)

    case skill do
      nil ->
        {:error, :not_found}

      skill ->
        {:ok, skill}
    end
  end

  defp parse_check_skill_known(skill, save) do
    case skill.id in save.skill_ids do
      true ->
        {:ok, skill}

      false ->
        {:error, :not_known, skill}
    end
  end

  defp parse_check_skill_level(skill, save) do
    case skill.level <= save.level do
      true ->
        {:ok, skill}

      false ->
        {:error, :level_too_low, skill}
    end
  end

  @impl Game.Command
  @doc """
  Look at your info sheet
  """
  def run(command, state)

  def run({}, %{socket: socket, save: save}) do
    skills =
      save.skill_ids
      |> Skills.skills()
      |> Enum.filter(&(&1.level <= save.level))
      |> Enum.sort_by(& &1.level)

    socket |> @socket.echo(Format.skills(skills))
    :ok
  end

  def run({:all}, %{socket: socket, save: save}) do
    skills =
      save.skill_ids
      |> Skills.skills()
      |> Enum.sort_by(& &1.level)

    socket |> @socket.echo(Format.skills(skills))
    :ok
  end

  def run({%{command: command}, command}, %{socket: socket, target: target})
      when is_nil(target) do
    socket |> @socket.echo("You don't have a target.")
    :ok
  end

  def run({skill, :level_too_low}, state) do
    state.socket |> @socket.echo("You are too low of a level to use #{Format.skill_name(skill)}.")
    :ok
  end

  def run({skill, :not_known}, state) do
    state.socket |> @socket.echo("You do not know #{Format.skill_name(skill)}.")
    :ok
  end

  def run({skill, command}, state = %{save: %{room_id: room_id}, target: target}) do
    new_target =
      command
      |> String.replace(skill.command, "")
      |> String.trim()

    {:ok, room} = @room.look(room_id)

    with {:ok, target} <- maybe_replace_target_with_self(state, skill, target),
         {:ok, target} <- find_target(state, room, target, new_target),
         {:ok, skill} <- check_skill_level(state, skill),
         {:ok, skill} <- check_cooldown(state, skill) do
      use_skill(skill, target, state)
    else
      {:error, :not_found} ->
        state.socket |> @socket.echo("Your target could not be found.")

      {:error, :skill, :level_too_low} ->
        state.socket |> @socket.echo("You are not high enough level to use this skill.")

      {:error, :skill_not_ready, remaining_seconds} ->
        state.socket |> @socket.echo("#{Format.skill_name(skill)} is not ready yet.")
        Hint.gate(state, "skills.cooldown_time", %{remaining_seconds: remaining_seconds})
        :ok
    end
  end

  defp maybe_replace_target_with_self(state, skill, target) do
    case skill.require_target do
      true ->
        {:ok, {:user, state.user.id}}

      false ->
        {:ok, target}
    end
  end

  defp check_skill_level(%{save: save}, skill) do
    case skill.level > save.level do
      true ->
        {:error, :skill, :level_too_low}

      false ->
        {:ok, skill}
    end
  end

  defp check_cooldown(%{skills: skills}, skill) do
    case Map.get(skills, skill.id) do
      nil ->
        {:ok, skill}

      last_used_at ->
        difference = Timex.diff(Timex.now(), last_used_at, :milliseconds)

        case difference > skill.cooldown_time do
          true ->
            {:ok, skill}

          false ->
            remaining_seconds = round((skill.cooldown_time - difference) / 1000)
            {:error, :skill_not_ready, remaining_seconds}
        end
    end
  end

  defp use_skill(skill, target, state) do
    %{socket: socket, user: user, save: save = %{stats: stats}} = state

    {state, target} = maybe_change_target(state, skill, target)

    case stats |> Skill.pay(skill) do
      {:ok, stats} ->
        save = %{save | stats: stats}

        player_effects = save |> Item.effects_on_player()

        effects = Skill.filter_effects(player_effects ++ skill.effects, skill)

        effects =
          stats
          |> Effect.calculate_stats_from_continuous_effects(state)
          |> Effect.calculate(effects)

        Character.apply_effects(
          target,
          effects,
          {:user, user},
          Format.skill_usee(skill, user: {:user, user}, target: target)
        )

        socket |> @socket.echo(Format.skill_user(skill, {:user, user}, target))
        state |> GMCP.skill_inactive(skill)

        state =
          state
          |> set_timeout(skill)
          |> Map.put(:save, save)
          |> track_stat_usage(effects)

        {:skip, :prompt, state}

      {:error, _} ->
        socket |> @socket.echo(~s(You don't have enough skill points to use "#{skill.command}"))
        {:update, state}
    end
  end

  defp track_stat_usage(state = %{save: save}, effects) do
    save = Experience.track_stat_usage(save, effects)
    %{state | save: save}
  end

  defp maybe_change_target(state, skill, target) do
    case skill.require_target do
      true ->
        {state, target}

      false ->
        _maybe_change_target(state, target)
    end
  end

  defp _maybe_change_target(state, target) do
    case Character.who(target) == state.target do
      true ->
        {state, target}

      false ->
        case target do
          {:npc, npc} ->
            {:update, state} = Target.target_npc(npc, state.socket, state)
            {state, target}

          {:user, user} ->
            {:update, state} = Target.target_user(user, state.socket, state)
            {state, target}
        end
    end
  end

  @doc """
  Find a target from state target

      iex> Game.Command.Skills.find_target(%{npcs: []}, {:npc, 1})
      {:error, :not_found}

      iex> Game.Command.Skills.find_target(%{npcs: [%{id: 1, name: "Bandit"}]}, {:npc, 1})
      {:ok, {:npc, %{id: 1, name: "Bandit"}}}

      iex> Game.Command.Skills.find_target(%{players: []}, {:user, 1})
      {:error, :not_found}

      iex> Game.Command.Skills.find_target(%{players: [%{id: 1, name: "Bandit"}]}, {:user, 1})
      {:ok, {:user, %{id: 1, name: "Bandit"}}}

      iex> Game.Command.Skills.find_target(%{}, %{players: [%{id: 1, name: "Bandit"}], npcs: []}, {:user, 2}, "bandit")
      {:ok, {:user, %{id: 1, name: "Bandit"}}}
  """
  @spec find_target(Room.t(), Character.t(), String.t()) :: Character.t()
  def find_target(state, room, target, new_target \\ "")

  def find_target(state, room, character, new_target) when new_target != "" do
    case Target.find_target(state, new_target, room.players, room.npcs) do
      nil ->
        find_target(room, character)

      target ->
        {:ok, target}
    end
  end

  def find_target(_state, room, character, _), do: find_target(room, character)

  def find_target(%{npcs: npcs}, {:npc, id}) do
    case Enum.find(npcs, &(&1.id == id)) do
      nil ->
        {:error, :not_found}

      npc ->
        {:ok, {:npc, npc}}
    end
  end

  def find_target(%{players: users}, {:user, id}) do
    case Enum.find(users, &(&1.id == id)) do
      nil ->
        {:error, :not_found}

      user ->
        {:ok, {:user, user}}
    end
  end

  def find_target(_, _), do: {:error, :not_found}

  defp set_timeout(state, skill) do
    Process.send_after(self(), {:skill, :ready, skill}, skill.cooldown_time)
    skills = Map.put(state.skills, skill.id, Timex.now())
    %{state | skills: skills}
  end
end
