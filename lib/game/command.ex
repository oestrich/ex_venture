defmodule Game.Command do
  use Networking.Socket
  use Game.Room

  alias Data.Room
  alias Game.Help
  alias Game.Session

  def parse(command) do
    case command do
      "help " <> topic -> {:help, topic |> String.downcase}
      "help" -> {:help}
      "look" -> {:look}
      "quit" -> {:quit}
      "say " <> message -> {:say, message}
      "who" <> _extra -> {:who}
      _ -> {:error, :bad_parse}
    end
  end

  def run({:help}, %{socket: socket}) do
    socket |> @socket.echo(Help.base)
  end
  def run({:help, topic}, %{socket: socket}) do
    socket |> @socket.echo(Help.topic(topic))
  end

  def run({:look}, %{socket: socket, room_id: room_id}) do
    room = @room.look(room_id)
    exits = Room.exits(room)
    |> Enum.map(fn (direction) -> "{white}#{direction}{/white}" end)
    |> Enum.join(" ")
    socket |> @socket.echo("{green}#{room.name}{/green}\n#{room.description}\nExits: #{exits}")
  end

  def run({:quit}, %{socket: socket}) do
    socket |> @socket.echo("Good bye.")
    socket |> @socket.disconnect
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

  def run({:error, :bad_parse}, %{socket: socket}) do
    socket |> @socket.echo("Unknown command")
  end
end
