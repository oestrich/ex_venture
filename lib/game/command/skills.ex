defmodule Game.Command.Skills do
  @moduledoc """
  Parse out class skills
  """

  use Game.Command
  alias Game.Effect
  alias Game.Character

  @commands ["skills"]

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
  def run({skill, _command}, _session, %{socket: socket, user: user, save: %{room_id: room_id, stats: stats}, target: target}) do
    room = @room.look(room_id)

    case find_target(room, target) do
      nil ->
        socket |> @socket.echo("Your target could not be found.")
      target ->
        effects = stats |> Effect.calculate(skill.effects)
        Character.apply_effects(target, effects, {:user, user}, Format.skill_usee(skill, {:user, user}))
        socket |> @socket.echo(Format.skill_user(skill, target))
    end

    :ok
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
