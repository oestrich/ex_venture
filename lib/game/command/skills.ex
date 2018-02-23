defmodule Game.Command.Skills do
  @moduledoc """
  Parse out class skills
  """

  use Game.Command

  alias Game.Character
  alias Game.Command
  alias Game.Command.Target
  alias Game.Effect
  alias Game.Item
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
    [ ] > {white}skills{/white}
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
    skill =
      save.skill_ids
      |> Skills.skills()
      |> Enum.filter(&(&1.level <= save.level))
      |> Enum.find(fn skill ->
        Regex.match?(~r(^#{skill.command}), command)
      end)

    case skill do
      nil ->
        {:error, :bad_parse, command}

      skill ->
        %Command{text: command, module: __MODULE__, args: {skill, command}}
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

  def run({skill, command}, state = %{socket: socket, save: %{room_id: room_id}, target: target}) do
    new_target =
      command
      |> String.replace(skill.command, "")
      |> String.trim()

    room = @room.look(room_id)

    case find_target(room, target, new_target) do
      nil ->
        socket |> @socket.echo("Your target could not be found.")
        :ok

      target ->
        skill |> use_skill(target, state)
    end
  end

  defp use_skill(%{level: skill_level}, _traget, state = %{save: %{level: player_level}})
       when skill_level > player_level do
    %{socket: socket} = state
    socket |> @socket.echo("You are not high enough level to use this skill.")
    :ok
  end

  defp use_skill(skill, target, state) do
    %{socket: socket, user: user, save: save = %{stats: stats}} = state

    {target, state} = maybe_change_target(target, state)

    case stats |> Skill.pay(skill) do
      {:ok, stats} ->
        save = %{save | stats: stats}

        player_effects = save |> Item.effects_on_player()
        effects = stats |> Effect.calculate(player_effects ++ skill.effects)

        Character.apply_effects(
          target,
          effects,
          {:user, user},
          Format.skill_usee(skill, user: {:user, user})
        )

        socket |> @socket.echo(Format.skill_user(skill, effects, target))

        {:update, %{state | save: save}}

      {:error, _} ->
        socket |> @socket.echo(~s(You don't have enough skill points to use "#{skill.command}"))
        {:update, state}
    end
  end

  def maybe_change_target(target, state) do
    case Character.who(target) == state.target do
      true ->
        {target, state}

      false ->
        case target do
          {:npc, npc} ->
            {:update, state} = Target.target_npc(npc, state.socket, state)
            {target, state}

          {:user, user} ->
            {:update, state} = Target.target_user(user, state.socket, state)
            {target, state}
        end
    end
  end

  @doc """
  Find a target from state target

      iex> Game.Command.Skills.find_target(%{npcs: []}, {:npc, 1})
      nil

      iex> Game.Command.Skills.find_target(%{npcs: [%{id: 1, name: "Bandit"}]}, {:npc, 1})
      {:npc, %{id: 1, name: "Bandit"}}

      iex> Game.Command.Skills.find_target(%{players: []}, {:user, 1})
      nil

      iex> Game.Command.Skills.find_target(%{players: [%{id: 1, name: "Bandit"}]}, {:user, 1})
      {:user, %{id: 1, name: "Bandit"}}

      iex> Game.Command.Skills.find_target(%{players: [%{id: 1, name: "Bandit"}], npcs: []}, {:user, 2}, "bandit")
      {:user, %{id: 1, name: "Bandit"}}
  """
  @spec find_target(Room.t(), Character.t()) :: Character.t()
  def find_target(room, target, new_target \\ "")

  def find_target(%{players: players, npcs: npcs}, _, new_target) when new_target != "" do
    Target.find_target(new_target, players, npcs)
  end

  def find_target(%{npcs: npcs}, {:npc, id}, _new_target) do
    case Enum.find(npcs, &(&1.id == id)) do
      nil -> nil
      npc -> {:npc, npc}
    end
  end

  def find_target(%{players: users}, {:user, id}, _new_target) do
    case Enum.find(users, &(&1.id == id)) do
      nil -> nil
      user -> {:user, user}
    end
  end
end
