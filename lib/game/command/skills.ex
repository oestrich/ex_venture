defmodule Game.Command.Skills do
  @moduledoc """
  Parse out class skills
  """

  use Game.Command

  alias Game.Character
  alias Game.Effect
  alias Game.Item
  alias Game.Skill

  @commands ["skills"]
  @must_be_alive true

  @short_help "List out your class skills"
  @full_help """
  Example: skills
  """

  @doc """
  Look at your info sheet
  """
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({}, _session, %{socket: socket, user: user}) do
    socket |> @socket.echo(Format.skills(user.class))
    :ok
  end
  def run({_skill, _command}, _session, %{socket: socket, target: target}) when is_nil(target) do
    socket |> @socket.echo("You don't have a target.")
    :ok
  end
  def run({skill, _command}, _session, state = %{socket: socket, save: %{room_id: room_id}, target: target}) do
    room = @room.look(room_id)
    case find_target(room, target) do
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
  defp use_skill(skill, target, state = %{socket: socket, user: user, save: %{stats: stats}}) do
    %{save: save} = state

    case stats |> Skill.pay(skill) do
      {:ok, stats} ->
        save = %{save | stats: stats}

        wearing_effects = save |> Item.effects_from_wearing()
        effects = stats |> Effect.calculate(wearing_effects ++ skill.effects)
        Character.apply_effects(target, effects, {:user, user}, skill.usee_text)
        socket |> @socket.echo(Format.skill_user(skill, effects, target))

        {:update, %{state | save: save}}
      {:error, _} ->
        socket |> @socket.echo(~s(You don't have enough skill points to use "#{skill.command}"))
        :ok
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
  """
  @spec find_target(room :: Room.t, target :: {atom, integer}) :: {:npc, map} | {:user, map}
  def find_target(room, target)
  def find_target(%{npcs: npcs}, {:npc, id}) do
    case Enum.find(npcs, &(&1.id == id)) do
      nil -> nil
      npc -> {:npc, npc}
    end
  end
  def find_target(%{players: users}, {:user, id}) do
    case Enum.find(users, &(&1.id == id)) do
      nil -> nil
      user -> {:user, user}
    end
  end
end
