defmodule Game.Command.Tell do
  @moduledoc """
  Tell/reply to players
  """

  use Game.Command

  alias Game.Channel
  alias Game.Format.Channels, as: FormatChannels
  alias Game.Session
  alias Game.Utility

  commands(["tell", "reply"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Tell"
  def help(:short), do: "Send a message to one player that is online"

  def help(:full) do
    """
    Send a message to one player that is online. You can reply quickly to the
    last tell you received by using {command}reply{/command}.

    Example:
    [ ] > {command}tell player Hello{/command}

    [ ] > {command}reply Hello{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

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

  def run({"reply", message}, state = %{reply_to: reply_to}) do
    case reply_to do
      nil ->
        state |> Socket.echo(gettext("There is no one to reply to."))

      {:player, player} ->
        message |> reply_to_player(player, state)

      {:gossip, player_name} ->
        message |> reply_to_gossip(player_name, state)

      {:npc, npc} ->
        message |> reply_to_npc(npc, state)
    end

    :ok
  end

  defp maybe_tell_player(state = %{character: from}, message) do
    [player_name | message] = String.split(message, " ")
    message = Enum.join(message, " ")

    case Session.Registry.find_connected_player(name: player_name) do
      nil ->
        state

      %{player: player} ->
        message = Message.format(message)
        state |> Socket.echo(FormatChannels.send_tell({:player, player}, message))
        Channel.tell({:player, player}, {:player, from}, Message.tell(from, message))
        {:update, %{state | reply_to: {:player, player}}}
    end
  end

  defp maybe_tell_npc(:ok, _message), do: :ok

  defp maybe_tell_npc({:update, state}, _message), do: {:update, state}

  defp maybe_tell_npc(state = %{save: %{room_id: room_id}, character: from}, message) do
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
        state |> Socket.echo(FormatChannels.send_tell({:npc, npc}, message))
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

  defp maybe_fail_tell(state, message) do
    [name | _] = String.split(message, " ")
    message = gettext(~s("%{name}" is not online.), name: name)
    state |> Socket.echo(message)
  end

  defp tell_gossip(state, player_name, message) do
    [name, game] = String.split(player_name, "@")

    case Gossip.send_tell(state.character.name, game, name, message) do
      :ok ->
        state
        |> Socket.echo(FormatChannels.send_tell({:player, %{name: player_name}}, message))

        {:update, %{state | reply_to: {:gossip, player_name}}}

      {:error, :offline} ->
        state |> Socket.echo(gettext("Error: Gossip is offline."))

      {:error, "game offline"} ->
        state |> Socket.echo(gettext("The remote game is offline."))

      {:error, "player offline"} ->
        state |> Socket.echo(gettext("The remote player is offline."))

      {:error, "not supported"} ->
        state |> Socket.echo(gettext("The remote game does not support tells."))

      {:error, message} ->
        message = gettext(~s(Error: Gossip responded with "%{message}".), message: message)
        state |> Socket.echo(message)
    end
  end

  defp reply_to_player(message, reply_to, state = %{character: from}) do
    case Session.Registry.find_connected_player(reply_to.id) do
      nil ->
        message = gettext(~s("%{name}" is not online.), name: reply_to.name)
        state |> Socket.echo(message)

      _ ->
        message = Message.format(message)
        state |> Socket.echo(FormatChannels.send_tell({:player, reply_to}, message))
        Channel.tell({:player, reply_to}, {:player, from}, Message.tell(from, message))
    end
  end

  defp reply_to_gossip(message, player_name, state) do
    tell_gossip(state, player_name, message)
  end

  defp reply_to_npc(message, reply_to, state = %{character: from, save: %{room_id: room_id}}) do
    {:ok, room} = @environment.look(room_id)
    npc = room.npcs |> Enum.find(&Utility.matches?(&1, reply_to.name))

    case npc do
      nil ->
        message = gettext("Could not find %{name}.", name: Format.npc_name(reply_to))
        state |> Socket.echo(message)

      _ ->
        message = Message.format(message)
        state |> Socket.echo(FormatChannels.send_tell({:npc, reply_to}, message))
        Channel.tell({:npc, reply_to}, {:player, from}, Message.tell(from, message))
    end
  end
end
