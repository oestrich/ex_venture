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
    Targets an enemy for skills.

    Set your new target by name:
    [ ] > {command}target bandit{/command}

    View your current target:
    [ ] > {command}target{/command}

    Skills can also set a new target by adding the target's name after
    the skill command:
    [ ] > {command}slash bandit{/command}

    When you defeat an enemy, a new target might be chosen for you. If there
    are more than one enemy attacking you, the next alive enemy will be picked
    as your target.
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
        message = gettext(~s(Could not find target "%{name}".), name: target)
        socket |> @socket.echo(message)

      {:npc, npc} ->
        npc |> target_npc(socket, state)

      {:player, player} ->
        player |> target_player(socket, state)
    end
  end

  @doc """
  Target an NPC
  """
  @spec target_npc(NPC.t(), pid, map) :: {:update, map}
  def target_npc(npc, socket, state)

  def target_npc(npc = %{id: id}, socket, state = %{user: user}) do
    Character.being_targeted({:npc, id}, {:player, user})
    message = gettext("You are now targeting %{name}.", name: Format.npc_name(npc))
    socket |> @socket.echo(message)
    state |> GMCP.target({:npc, npc})

    {:update, Map.put(state, :target, {:npc, id})}
  end

  @doc """
  Target a player

  Does not target if the target is too low of health
  """
  @spec target_player(User.t(), pid, map) :: :ok | {:update, map}
  def target_player(player, socket, state)

  def target_player(player = %{save: %{stats: %{health_points: health_points}}}, socket, _state)
      when health_points < 1 do
    message = gettext("%{name} could not be targeted.", name: Format.target_name({:player, player}))
    socket |> @socket.echo(message)
  end

  def target_player(player = %{id: id}, socket, state = %{user: user}) do
    Character.being_targeted({:player, id}, {:player, user})
    message = gettext("You are now targeting %{name}.", name: Format.player_name(player))
    socket |> @socket.echo(message)
    state |> GMCP.target({:player, player})

    {:update, Map.put(state, :target, {:player, id})}
  end

  @doc """
  Display your target
  """
  @spec display_target(pid, Character.t(), map) :: :ok
  def display_target(socket, target, room)

  def display_target(socket, nil, _room) do
    socket |> @socket.echo(gettext("You don't have a target."))
  end

  def display_target(socket, {:npc, npc_id}, room) do
    case Enum.find(room.npcs, &(&1.id == npc_id)) do
      nil ->
        socket |> @socket.echo(gettext("Your target could not be found."))

      npc ->
        message = gettext("Your target is %{name}.", name: Format.npc_name(npc))
        socket |> @socket.echo(message)
    end
  end

  def display_target(socket, {:player, player_id}, room) do
    case Enum.find(room.players, &(&1.id == player_id)) do
      nil ->
        socket |> @socket.echo(gettext("Your target could not be found."))

      player ->
        message = gettext("Your target is %{name}.", name: Format.player_name(player))
        socket |> @socket.echo(message)
    end
  end

  @doc """
  Find a user/npc by name

      iex> Game.Command.Target.find_target(%{}, "player", [%{name: "Player"}], [%{name: "Bandit"}])
      {:player, %{name: "Player"}}

      iex> Game.Command.Target.find_target(%{}, "bandit", [%{name: "Player"}], [%{name: "Bandit"}])
      {:npc, %{name: "Bandit"}}

      iex> Game.Command.Target.find_target(%{}, "Bandit", [%{name: "Bandit"}], [%{name: "Bandit"}])
      {:player, %{name: "Bandit"}}

      iex> Game.Command.Target.find_target(%{user: %{name: "Player"}}, "self", [%{name: "Bandit"}], [%{name: "Bandit"}])
      {:player, %{name: "Player"}}
  """
  def find_target(state, name, players, npcs) do
    case name do
      "self" ->
        {:player, state.user}

      _ ->
        _find_target(name, players, npcs)
    end
  end

  defp _find_target(name, players, npcs) do
    case find_target_in_list(players, name) do
      {:ok, player} ->
        {:player, player}

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
