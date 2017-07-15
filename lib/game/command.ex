defmodule Game.Command do
  alias Game.Color
  alias Game.Help
  alias Game.Session

  @socket Application.get_env(:ex_mud, :networking)[:socket_module]

  def parse(command) do
    case command do
      "say " <> message -> {:say, message}
      "who" <> _extra -> {:who}
      "quit" -> {:quit}
      "help" -> {:help}
      "help " <> topic -> {:help, topic}
      _ -> {:error, :bad_parse}
    end
  end

  def run({:say, message}, %{user: user}) do
    Session.Registry.connected_players()
    |> Enum.each(fn ({pid, _}) ->
      GenServer.cast(pid, {:echo, Color.format("{blue}#{user.username}{/blue}: #{message}")})
    end)
  end

  def run({:who}, %{socket: socket}) do
    Session.Registry.connected_players()
    |> Enum.each(fn ({_pid, user}) ->
      socket |> @socket.echo(user.username)
    end)
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
