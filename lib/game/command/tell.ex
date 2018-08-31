defmodule Game.Command.Tell do
  @moduledoc """
  Tell/reply to players
  """

  use Game.Command

  alias Game.Channel
  alias Game.Session
  alias Game.Utility

  commands(["tell", "reply"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Tell"
  def help(:short), do: "Send a message to one player that is online"

  def help(:full) do
    """
    #{help(:short)}. You can reply quickly to the last tell
    you received by using {command}reply{/command}.

    Example:
    [ ] > {command}tell player Hello{/command}

    [ ] > {command}reply Hello{/command}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Tell.parse("tell player hello")
      {"tell", "player hello"}

      iex> Game.Command.Tell.parse("reply hello")
      {"reply", "hello"}

      iex> Game.Command.Tell.parse("unknown hi")
      {:error, :bad_parse, "unknown hi"}
  """
  @spec parse(String.t()) :: {atom}
  def parse(command)
  def parse("tell " <> message), do: {"tell", message}
  def parse("reply " <> message), do: {"reply", message}

  @impl Game.Command
  @doc """
  Send to all connected players
  """
  def run(command, state)

  def run({"tell", message}, state) do
    state
    |> maybe_tell_player(message)
    |> maybe_tell_npc(message)
    |> maybe_tell_gossip(message)
    |> maybe_fail_tell(message)
  end

  def run({"reply", message}, state = %{socket: socket, reply_to: reply_to}) do
    case reply_to do
      nil ->
        socket |> @socket.echo("There is no one to reply to.")

      {:player, player} ->
        message |> reply_to_player(player, state)

      {:gossip, player_name} ->
        message |> reply_to_gossip(player_name, state)

      {:npc, npc} ->
        message |> reply_to_npc(npc, state)
    end

    :ok
  end

  defp maybe_tell_player(state = %{socket: socket, user: from}, message) do
    [player_name | message] = String.split(message, " ")
    message = Enum.join(message, " ")

    player =
      Session.Registry.connected_players()
      |> Enum.find(fn %{player: player} ->
        player.name |> String.downcase() == player_name |> String.downcase()
      end)

    case player do
      nil ->
        state

      %{player: player} ->
        message = Message.format(message)
        socket |> @socket.echo(Format.send_tell({:player, player}, message))
        Channel.tell({:player, player}, {:player, from}, Message.tell(from, message))
        {:update, %{state | reply_to: {:player, player}}}
    end
  end

  defp maybe_tell_npc(:ok, _message), do: :ok

  defp maybe_tell_npc({:update, state}, _message), do: {:update, state}

  defp maybe_tell_npc(state = %{socket: socket, save: %{room_id: room_id}, user: from}, message) do
    {:ok, room} = @environment.look(room_id)

    npc =
      room.npcs
      |> Enum.find(fn npc ->
        Utility.name_matches?(npc, message)
      end)

    case npc do
      nil ->
        state

      _ ->
        message = Utility.strip_name(npc, message)
        message = Message.format(message)
        socket |> @socket.echo(Format.send_tell({:npc, npc}, message))
        Channel.tell({:npc, npc}, {:player, from}, Message.tell(from, message))
        {:update, %{state | reply_to: {:npc, npc}}}
    end
  end

  defp maybe_tell_gossip(:ok, _message), do: :ok

  defp maybe_tell_gossip({:update, state}, _message), do: {:update, state}

  defp maybe_tell_gossip(state, message) do
    [player_name | message] = String.split(message, " ")
    message = Enum.join(message, " ")

    case String.contains?(player_name, "@") do
      true ->
        tell_gossip(state, player_name, message)

      false ->
        state
    end
  end

  defp maybe_fail_tell(:ok, _message), do: :ok

  defp maybe_fail_tell({:update, state}, _message), do: {:update, state}

  defp maybe_fail_tell(%{socket: socket}, message) do
    [name | _] = String.split(message, " ")
    socket |> @socket.echo(~s("#{name}" is not online.))
  end

  defp tell_gossip(state, player_name, message) do
    [name, game] = String.split(player_name, "@")

    case Gossip.send_tell(state.user.name, game, name, message) do
      :ok ->
        state.socket |> @socket.echo(Format.send_tell({:player, %{name: player_name}}, message))
        {:update, %{state | reply_to: {:gossip, player_name}}}

      {:error, :offline} ->
        state.socket |> @socket.echo("Error: Gossip is offline.")

      {:error, "game offline"} ->
        state.socket |> @socket.echo("The remote game is offline.")

      {:error, "player offline"} ->
        state.socket |> @socket.echo("The remote player is offline.")

      {:error, "not supported"} ->
        state.socket |> @socket.echo("The remote game does not support tells.")

      {:error, message} ->
        state.socket |> @socket.echo(~s(Error: Gossip responded with "#{message}".))
    end
  end

  defp reply_to_player(message, reply_to, %{socket: socket, user: from}) do
    player =
      Session.Registry.connected_players()
      |> Enum.find(fn %{player: player} -> player.id == reply_to.id end)

    case player do
      nil ->
        socket |> @socket.echo(~s["#{reply_to.name}" is not online.])

      _ ->
        message = Message.format(message)
        socket |> @socket.echo(Format.send_tell({:player, reply_to}, message))
        Channel.tell({:player, reply_to}, {:player, from}, Message.tell(from, message))
    end
  end

  defp reply_to_gossip(message, player_name, state) do
    tell_gossip(state, player_name, message)
  end

  defp reply_to_npc(message, reply_to, %{socket: socket, user: from, save: %{room_id: room_id}}) do
    {:ok, room} = @environment.look(room_id)
    npc = room.npcs |> Enum.find(&Utility.matches?(&1, reply_to.name))

    case npc do
      nil ->
        socket |> @socket.echo("Could not find #{Format.npc_name(reply_to)}.")

      _ ->
        message = Message.format(message)
        socket |> @socket.echo(Format.send_tell({:npc, reply_to}, message))
        Channel.tell({:npc, reply_to}, {:player, from}, Message.tell(from, message))
    end
  end
end
