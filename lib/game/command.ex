defmodule Game.Command do
  use Networking.Socket

  alias Game.Help
  alias Game.Session

  def parse(command) do
    case command do
      "say " <> message -> {:say, message}
      "who" <> _extra -> {:who}
      "quit" -> {:quit}
      "help" -> {:help}
      "help " <> topic -> {:help, topic |> String.downcase}
      _ -> {:error, :bad_parse}
    end
  end

  def run({:say, message}, %{user: user}) do
    Session.Registry.connected_players()
    |> Enum.each(fn ({pid, _}) ->
      GenServer.cast(pid, {:echo, "{blue}#{user.username}{/blue}: #{message}"})
    end)
  end

  def run({:who}, %{socket: socket}) do
    usernames = Session.Registry.connected_players()
    |> Enum.map(fn ({_pid, user}) ->
      "  - {blue}#{user.username}{/blue}\n"
    end)
    |> Enum.join("")

    socket |> @socket.echo("Players online:\n#{usernames}")
  end

  def run({:quit}, %{socket: socket}) do
    socket |> @socket.echo("Good bye.")
    socket |> @socket.disconnect
  end

  def run({:help}, %{socket: socket}) do
    socket |> @socket.echo(Help.base)
  end

  def run({:help, topic}, %{socket: socket}) do
    socket |> @socket.echo(Help.topic(topic))
  end

  def run({:error, :bad_parse}, %{socket: socket}) do
    socket |> @socket.echo("Unknown command")
  end
end
