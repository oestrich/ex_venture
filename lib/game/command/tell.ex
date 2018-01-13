defmodule Game.Command.Tell do
  @moduledoc """
  Tell/reply to players
  """

  use Game.Command

  alias Game.Channel
  alias Game.Session

  commands ["tell", "reply"], parse: false

  @impl Game.Command
  def help(:topic), do: "Tell"
  def help(:short), do: "Send a message to one player that is online"
  def help(:full) do
    """
    #{help(:short)}. You can reply quickly to the last tell
    you received by using {white}reply{/white}.

    Example:
    [ ] > {white}tell player Hello{/white}
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
  @spec parse(command :: String.t) :: {atom}
  def parse(command)
  def parse("tell " <> message), do: {"tell", message}
  def parse("reply " <> message), do: {"reply", message}
  def parse(command), do: {:error, :bad_parse, command}

  @doc """
  Send to all connected players
  """
  @impl Game.Command
  def run(command, session, state)
  def run({"tell", message}, _session, %{socket: socket, user: from}) do
    [player_name | message] = String.split(message, " ")
    message = Enum.join(message, " ")

    player = Session.Registry.connected_players()
    |> Enum.find(fn ({_, user}) ->
      user.name |> String.downcase() == player_name |> String.downcase()
    end)

    case player do
      nil ->
        socket |> @socket.echo(~s["#{player_name}" is not online])
      {_, user} ->
        socket |> @socket.echo(Format.send_tell({:user, user}, message))
        Channel.tell({:user, user}, {:user, from}, Message.tell(from, message))
    end

    :ok
  end
  def run({"reply", message}, _session, state) do
    reply_to(message, state)
    :ok
  end

  defp reply_to(_message, %{socket: socket, reply_to: nil}) do
    socket |> @socket.echo("There is no one to reply to.")
  end
  defp reply_to(message, %{socket: socket, user: from, reply_to: {:user, reply_to}}) do
    player = Session.Registry.connected_players()
    |> Enum.find(fn ({_, player}) -> player.id == reply_to.id end)

    case player do
      nil ->
        socket |> @socket.echo(~s["#{reply_to.name}" is not online])
      _ ->
        socket |> @socket.echo(Format.send_tell({:user, reply_to}, message))
        Channel.tell({:user, reply_to}, {:user, from}, Message.tell(from, message))
    end
  end
end
