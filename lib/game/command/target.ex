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

  commands([{"target", ["t"]}], parse: false)

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

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Target.parse("target clear")
      {:clear}

      iex> Game.Command.Target.parse("target bandit")
      {:set, "bandit"}

      iex> Game.Command.Target.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  @spec parse(String.t()) :: {any()}
  def parse(command)
  def parse("target clear"), do: {:clear}
  def parse("target " <> name), do: {:set, name}
  def parse("t " <> name), do: {:set, name}
  def parse("target"), do: {}

  @impl Game.Command
  @doc """
  Target an enemy
  """
  def run(command, state)

  def run({:clear}, state) do
    state |> GMCP.clear_target()
    {:update, Map.put(state, :target, nil)}
  end

  def run({:set, target}, state = %{save: %{room_id: room_id}}) do
    {:ok, room} = Environment.look(room_id)
    state |> target_character(target, room, state)
  end

  def run({}, state = %{save: %{room_id: room_id}, target: target}) do
    {:ok, room} = Environment.look(room_id)
    state |> display_target(target, room)
    :ok
  end

  @doc """
  Target a character (NPC or PC)
  """
  @spec target_character(pid, String.t(), Room.t(), map) :: :ok | {:update, map}
  def target_character(state, target, room, state) do
    case find_target(state, target, room.players, room.npcs) do
      nil ->
        message = gettext(~s(Could not find target "%{name}".), name: target)
        state |> Socket.echo(message)

      npc = %{type: "npc"} ->
        npc |> target_npc(state, state)

      player = %{type: "player"} ->
        player |> target_player(state, state)
    end
  end

  @doc """
  Target an NPC
  """
  @spec target_npc(NPC.t(), pid, map) :: {:update, map}
  def target_npc(npc, state, state)

  def target_npc(npc, state, state) do
    Character.being_targeted(npc, Character.to_simple(state.character))
    message = gettext("You are now targeting %{name}.", name: Format.npc_name(npc))
    state |> Socket.echo(message)
    state |> GMCP.target(npc)

    {:update, Map.put(state, :target, npc)}
  end

  @doc """
  Target a player
  """
  @spec target_player(User.t(), pid, map) :: :ok | {:update, map}
  def target_player(player, state, state)

  def target_player(player, state, state) do
    Character.being_targeted(player, Character.to_simple(state.character))
    message = gettext("You are now targeting %{name}.", name: Format.player_name(player))
    state |> Socket.echo(message)
    state |> GMCP.target(player)

    {:update, Map.put(state, :target, player)}
  end

  @doc """
  Display your target
  """
  @spec display_target(pid, Character.t(), map) :: :ok
  def display_target(state, target, room)

  def display_target(state, nil, _room) do
    state |> Socket.echo(gettext("You don't have a target."))
  end

  def display_target(state, {:npc, npc_id}, room) do
    case Enum.find(room.npcs, &(&1.id == npc_id)) do
      nil ->
        state |> Socket.echo(gettext("Your target could not be found."))

      npc ->
        message = gettext("Your target is %{name}.", name: Format.npc_name(npc))
        state |> Socket.echo(message)
    end
  end

  def display_target(state, {:player, player_id}, room) do
    case Enum.find(room.players, &(&1.id == player_id)) do
      nil ->
        state |> Socket.echo(gettext("Your target could not be found."))

      player ->
        message = gettext("Your target is %{name}.", name: Format.player_name(player))
        state |> Socket.echo(message)
    end
  end

  @doc """
  Find a user/npc by name

      iex> state = %{character: %{type: "player", id: 1, name: "Player"}}
      iex> Game.Command.Target.find_target(state, "guard", [%{type: "player", name: "Guard"}], [%{type: "npc", name: "Bandit"}])
      %{type: "player", name: "Guard"}

      iex> state = %{character: %{type: "player", id: 1, name: "Player"}}
      iex> Game.Command.Target.find_target(state, "bandit", [%{type: "player", name: "Guard"}], [%{type: "npc", name: "Bandit"}])
      %{type: "npc", name: "Bandit"}

      iex> state = %{character: %{type: "player", id: 1, name: "Player"}}
      iex> Game.Command.Target.find_target(state, "guard", [%{type: "player", name: "Guard"}], [%{type: "npc", name: "Guard"}])
      %{type: "player", name: "Guard"}

      iex> state = %{character: %Character.Simple{type: "player", name: "Player"}}
      iex> Game.Command.Target.find_target(state, "self", [], [])
      %Character.Simple{type: "player", name: "Player"}
  """
  def find_target(state, name, players, npcs) do
    case name do
      "self" ->
        Character.to_simple(state.character)

      _ ->
        _find_target(name, players, npcs)
    end
  end

  defp _find_target(name, players, npcs) do
    case find_target_in_list(players, name) do
      {:ok, player} ->
        player

      {:error, :not_found} ->
        case find_target_in_list(npcs, name) do
          {:ok, npc} ->
            npc

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
