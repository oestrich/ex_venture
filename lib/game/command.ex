defmodule Game.Command do
  use Networking.Socket
  use Game.Room

  alias Data.Room
  alias Game.Account
  alias Game.Help
  alias Game.Session

  def parse(command) do
    case command do
      "e" -> {:east}
      "east" -> {:east}
      "help " <> topic -> {:help, topic |> String.downcase}
      "help" -> {:help}
      "look" -> {:look}
      "n" -> {:north}
      "north" -> {:north}
      "quit" -> {:quit}
      "s" -> {:south}
      "say " <> message -> {:say, message}
      "south" -> {:south}
      "w" -> {:west}
      "west" -> {:west}
      "who" <> _extra -> {:who}
      _ -> {:error, :bad_parse}
    end
  end

  def run({:east}, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case room do
      %{east_id: nil} -> :ok
      %{east_id: id} -> state |> move_to(id)
    end
  end

  def run({:help}, %{socket: socket}) do
    socket |> @socket.echo(Help.base)
    :ok
  end
  def run({:help, topic}, %{socket: socket}) do
    socket |> @socket.echo(Help.topic(topic))
    :ok
  end

  def run({:look}, %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    socket |> @socket.echo("{green}#{room.name}{/green}\n#{room.description}\nExits: #{exits(room)}\nPlayers: #{players(room)}")
    :ok
  end

  def run({:north}, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case room do
      %{north_id: nil} -> :ok
      %{north_id: id} -> state |> move_to(id)
    end
  end

  def run({:quit}, %{socket: socket, user: user, save: save}) do
    socket |> @socket.echo("Good bye.")
    socket |> @socket.disconnect

    user |> Account.save(save)

    :ok
  end

  def run({:say, message}, %{user: user}) do
    Session.Registry.connected_players()
    |> Enum.each(fn ({pid, _}) ->
      GenServer.cast(pid, {:echo, "{blue}#{user.username}{/blue}: #{message}"})
    end)
    :ok
  end
  def run({:south}, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case room do
      %{south_id: nil} -> :ok
      %{south_id: id} -> state |> move_to(id)
    end
  end

  def run({:west}, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case room do
      %{west_id: nil} -> :ok
      %{west_id: id} -> state |> move_to(id)
    end
  end

  def run({:who}, %{socket: socket}) do
    usernames = Session.Registry.connected_players()
    |> Enum.map(fn ({_pid, user}) ->
      "  - {blue}#{user.username}{/blue}\n"
    end)
    |> Enum.join("")

    socket |> @socket.echo("Players online:\n#{usernames}")
    :ok
  end

  def run({:error, :bad_parse}, %{socket: socket}) do
    socket |> @socket.echo("Unknown command")
    :ok
  end

  defp move_to(state = %{save: save, user: user}, room_id) do
    @room.leave(save.room_id, user)

    save = %{save | room_id: room_id}
    state = %{state | save: save}

    @room.enter(room_id, user)

    run({:look}, state)
    {:update, state}
  end

  defp exits(room) do
    Room.exits(room)
    |> Enum.map(fn (direction) -> "{white}#{direction}{/white}" end)
    |> Enum.join(" ")
  end

  def players(%{players: players}) do
    players
    |> Enum.map(fn (player) -> "{blue}#{player.username}{/blue}" end)
    |> Enum.join(", ")
  end
end
