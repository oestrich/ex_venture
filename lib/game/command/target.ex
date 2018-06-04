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
  alias Game.Utility

  @must_be_alive true

  commands([{"target", ["t"]}])

  @impl Game.Command
  def help(:topic), do: "Target"
  def help(:short), do: "Target an enemy"

  def help(:full) do
    """
    Targets an enemy for skills

    Example:
    [ ] > {command}target bandit{/command}
    """
  end

  @impl Game.Command
  @doc """
  Target an enemy
  """
  def run(command, state)

  def run({target}, state = %{socket: socket, save: %{room_id: room_id}}) do
    {:ok, room} = @environment.look(room_id)
    socket |> target_character(target, room, state)
  end

  def run({}, %{socket: socket, save: %{room_id: room_id}, target: target}) do
    {:ok, room} = @environment.look(room_id)
    socket |> display_target(target, room)
    :ok
  end

  @doc """
  Target a character (NPC or PC)
  """
  @spec target_character(pid, String.t(), Room.t(), map) :: :ok | {:update, map}
  def target_character(socket, target, room, state) do
    case find_target(state, target, room.players, room.npcs) do
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
  @spec target_npc(NPC.t(), pid, map) :: {:update, map}
  def target_npc(npc, socket, state)

  def target_npc(npc = %{id: id}, socket, state = %{user: user}) do
    Character.being_targeted({:npc, id}, {:user, user})
    socket |> @socket.echo("You are now targeting #{Format.npc_name(npc)}.")
    state |> GMCP.target({:npc, npc})
    {:update, Map.put(state, :target, {:npc, id})}
  end

  @doc """
  Target a user

  Does not target if the target is too low of health
  """
  @spec target_user(User.t(), pid, map) :: :ok | {:update, map}
  def target_user(user, socket, state)

  def target_user(user = %{save: %{stats: %{health_points: health_points}}}, socket, _state)
      when health_points < 1 do
    socket |> @socket.echo("#{Format.target_name({:user, user})} could not be targeted.")
    :ok
  end

  def target_user(player = %{id: id}, socket, state = %{user: user}) do
    Character.being_targeted({:user, id}, {:user, user})
    socket |> @socket.echo("You are now targeting #{Format.player_name(player)}.")
    state |> GMCP.target({:user, user})
    {:update, Map.put(state, :target, {:user, id})}
  end

  @doc """
  Display your target
  """
  @spec display_target(pid, Character.t(), map) :: :ok
  def display_target(socket, target, room)

  def display_target(socket, nil, _room) do
    socket |> @socket.echo("You don't have a target.")
  end

  def display_target(socket, {:npc, npc_id}, room) do
    case Enum.find(room.npcs, &(&1.id == npc_id)) do
      nil ->
        socket |> @socket.echo("Your target could not be found.")

      npc ->
        socket |> @socket.echo("Your target is #{Format.npc_name(npc)}")
    end
  end

  def display_target(socket, {:user, user_id}, room) do
    case Enum.find(room.players, &(&1.id == user_id)) do
      nil ->
        socket |> @socket.echo("Your target could not be found.")

      user ->
        socket |> @socket.echo("Your target is #{Format.player_name(user)}")
    end
  end

  @doc """
  Find a user/npc by name

      iex> Game.Command.Target.find_target(%{}, "player", [%{name: "Player"}], [%{name: "Bandit"}])
      {:user, %{name: "Player"}}

      iex> Game.Command.Target.find_target(%{}, "bandit", [%{name: "Player"}], [%{name: "Bandit"}])
      {:npc, %{name: "Bandit"}}

      iex> Game.Command.Target.find_target(%{}, "Bandit", [%{name: "Bandit"}], [%{name: "Bandit"}])
      {:user, %{name: "Bandit"}}

      iex> Game.Command.Target.find_target(%{user: %{name: "Player"}}, "self", [%{name: "Bandit"}], [%{name: "Bandit"}])
      {:user, %{name: "Player"}}
  """
  def find_target(state, name, users, npcs) do
    case name do
      "self" ->
        {:user, state.user}

      _ ->
        _find_target(name, users, npcs)
    end
  end

  defp _find_target(name, users, npcs) do
    case find_target_in_list(users, name) do
      {:ok, user} ->
        {:user, user}

      {:error, :not_found} ->
        case find_target_in_list(npcs, name) do
          {:ok, npc} ->
            {:npc, npc}

          {:error, :not_found} ->
            nil
        end
    end
  end

  @doc """
  Find a user/npc by name

      iex> Game.Command.Target.find_target_in_list([%{name: "Bandit"}], "bandit")
      {:ok, %{name: "Bandit"}}
  """
  @spec find_target_in_list([map], String.t()) :: String.t()
  def find_target_in_list(list, name) do
    case Enum.find(list, &Utility.matches?(&1.name, name)) do
      nil ->
        {:error, :not_found}

      target ->
        {:ok, target}
    end
  end
end
