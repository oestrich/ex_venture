defmodule Game.Command.Greet do
  @moduledoc """
  Greet/talk to players and NPCs
  """

  use Game.Command
  use Game.NPC

  alias Game.Utility

  commands(["greet", "talk to"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Greet"
  def help(:short), do: "Greet another player or NPC"

  def help(:full) do
    """
    #{help(:short)}. A way to greet another player or NPC. If you are
    greeting an NPC it will start a conversation with them. You may also get a quest
    from them if they are a quest giver.

    Example:
    [ ] > {command}greet guard{/command}

    [ ] > {command}talk to guard{/command}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Greet.parse("greet")
      {:greet, :help}

      iex> Game.Command.Greet.parse("greet guard")
      {:greet, "guard"}

      iex> Game.Command.Greet.parse("talk to guard")
      {:greet, "guard"}

      iex> Game.Command.Greet.parse("unknown hi")
      {:error, :bad_parse, "unknown hi"}
  """
  @spec parse(String.t()) :: {atom}
  def parse(command)
  def parse("greet"), do: {:greet, :help}
  def parse("greet " <> character), do: {:greet, character}
  def parse("talk to " <> character), do: {:greet, character}

  @impl Game.Command
  @doc """
  Greet another player
  """
  def run(command, state)

  def run({:greet, :help}, %{socket: socket}) do
    socket |> @socket.echo(gettext("You are not sure who to greet."))
  end

  def run({:greet, name}, state = %{save: %{room_id: room_id}}) do
    {:ok, room} = @environment.look(room_id)

    room
    |> maybe_greet_npc(name, state)
    |> maybe_greet_player(name, state)

    :ok
  end

  defp maybe_greet_npc(room, npc_name, %{socket: socket, user: user}) do
    npc = room.npcs |> Enum.find(&Utility.matches?(&1, npc_name))

    case npc do
      nil ->
        room

      npc ->
        @npc.greet(npc.id, user)
        socket |> @socket.echo(gettext("You greet %{name}.", name: Format.npc_name(npc)))
    end
  end

  defp maybe_greet_player(:ok, _player_name, _state), do: :ok

  defp maybe_greet_player(room, player_name, %{socket: socket}) do
    player = room.players |> Enum.find(&Utility.matches?(&1, player_name))

    case player do
      nil ->
        room

      player ->
        socket |> @socket.echo(gettext("You greet %{name}.", name: Format.player_name(player)))
    end
  end
end
