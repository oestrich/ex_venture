defmodule Game.Command.Target do
  @moduledoc """
  The "target" command
  """

  use Game.Command

  alias Data.NPC
  alias Data.Room
  alias Data.User
  alias Game.Character
  alias Game.Session.GMCP

  @commands ["target"]
  @aliases ["t"]
  @must_be_alive true

  @short_help "Target an enemy"
  @full_help """
  Targets an enemy for skills

  Example:
  [  ] > {white}target bandit{/white}
  """

  @doc """
  Target an enemy
  """
  def run(command, session, state)
  def run({target}, _session, state = %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    socket |> target_character(target, room, state)
  end
  def run({}, _session, %{socket: socket, save: %{room_id: room_id}, target: target}) do
    room = @room.look(room_id)
    socket |> display_target(target, room)
    :ok
  end

  @doc """
  Target a character (NPC or PC)
  """
  @spec target_character(socket :: pid, target :: String.t, room :: Room.t, state :: map) :: :ok | {:update, map}
  def target_character(socket, target, room, state) do
    case find_target(target, room.players, room.npcs) do
      nil ->
        socket |> @socket.echo(~s(Could not find target "#{target}".))
        :ok
      {:npc, npc} ->
        npc |> target_npc(socket, state)
      {:user, user} ->
        user |> target_user(socket, state)
    end
  end

  @doc """
  Target an NPC
  """
  @spec target_npc(npc :: NPC.t, socket :: pid, state :: map) :: {:update, state :: map}
  def target_npc(npc, socket, state)
  def target_npc(npc = %{id: id, name: name}, socket, state = %{user: user}) do
    Character.being_targeted({:npc, id}, {:user, user})
    socket |> @socket.echo("You are now targeting {yellow}#{name}{/yellow}.")
    state |> GMCP.targeted({:npc, npc})
    {:update, Map.put(state, :target, {:npc, id})}
  end

  @doc """
  Target a user

  Does not target if the target is too low of health
  """
  @spec target_user(user :: User.t, socket :: pid, state :: map) :: :ok | {:update, state :: map}
  def target_user(user, socket, state)
  def target_user(user = %{save: %{stats: %{health: health}}}, socket, _state) when health < 1 do
    socket |> @socket.echo("#{Format.target_name({:user, user})} could not be targeted.")
    :ok
  end
  def target_user(%{id: id, name: name}, socket, state = %{user: user}) do
    Character.being_targeted({:user, id}, {:user, user})
    socket |> @socket.echo("You are now targeting {blue}#{name}{/blue}.")
    state |> GMCP.targeted({:user, user})
    {:update, Map.put(state, :target, {:user, id})}
  end

  @doc """
  Display your target
  """
  @spec display_target(socket :: pid, target :: {atom, map}, room :: map) :: :ok
  def display_target(socket, target, room)
  def display_target(socket, nil, _room) do
    socket |> @socket.echo("You don't have a target.")
  end
  def display_target(socket, {:npc, npc_id}, room) do
    case Enum.find(room.npcs, &(&1.id == npc_id)) do
      nil ->
        socket |> @socket.echo("Your target could not be found.")
      npc ->
        socket |> @socket.echo("Your target is {yellow}#{npc.name}{/yellow}")
    end
  end
  def display_target(socket, {:user, user_id}, room) do
    case Enum.find(room.players, &(&1.id == user_id)) do
      nil ->
        socket |> @socket.echo("Your target could not be found.")
      user ->
        socket |> @socket.echo("Your target is {blue}#{user.name}{/blue}")
    end
  end

  @doc """
  Find a user/npc by name

      iex> Game.Command.Target.find_target("player", [%{name: "Player"}], [%{name: "Bandit"}])
      {:user, %{name: "Player"}}

      iex> Game.Command.Target.find_target("bandit", [%{name: "Player"}], [%{name: "Bandit"}])
      {:npc, %{name: "Bandit"}}

      iex> Game.Command.Target.find_target("Bandit", [%{name: "Bandit"}], [%{name: "Bandit"}])
      {:user, %{name: "Bandit"}}
  """
  def find_target(name, users, npcs) do
    case find_target_in_list(users, name) do
      nil ->
        case find_target_in_list(npcs, name) do
          nil -> nil
          npc -> {:npc, npc}
        end
      user -> {:user, user}
    end
  end

  @doc """
  Find a user/npc by name

      iex> Game.Command.Target.find_target_in_list([%{name: "Bandit"}], "bandit")
      %{name: "Bandit"}
  """
  @spec find_target_in_list(list :: [map], name :: String.t) :: String.t
  def find_target_in_list(list, name) do
    Enum.find(list, &(String.downcase(&1.name) == String.downcase(name)))
  end
end
