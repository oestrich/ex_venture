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

  def run({:east}, session, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case room do
      %{east_id: nil} -> :ok
      %{east_id: id} -> session |> move_to(state, id)
    end
  end

  def run({:help}, _session, %{socket: socket}) do
    socket |> @socket.echo(Help.base)
    :ok
  end
  def run({:help, topic}, _session, %{socket: socket}) do
    socket |> @socket.echo(Help.topic(topic))
    :ok
  end

  def run({:look}, _session, %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    socket |> @socket.echo("{green}#{room.name}{/green}\n#{room.description}\nExits: #{exits(room)}\nPlayers: #{players(room)}")
    :ok
  end

  def run({:north}, session, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case room do
      %{north_id: nil} -> :ok
      %{north_id: id} -> session |> move_to(state, id)
    end
  end

  def run({:quit}, _session, %{socket: socket, user: user, save: save}) do
    socket |> @socket.echo("Good bye.")
    socket |> @socket.disconnect

    user |> Account.save(save)

    :ok
  end

  def run({:say, message}, _session, %{user: user, save: %{room_id: room_id}}) do
    @room.say(room_id, "{blue}#{user.username}{/blue}: #{message}")
    :ok
  end

  def run({:south}, session, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case room do
      %{south_id: nil} -> :ok
      %{south_id: id} -> session |> move_to(state, id)
    end
  end

  def run({:west}, session, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case room do
      %{west_id: nil} -> :ok
      %{west_id: id} -> session |> move_to(state, id)
    end
  end

  def run({:who}, _session, %{socket: socket}) do
    usernames = Session.Registry.connected_players()
    |> Enum.map(fn ({_pid, user}) ->
      "  - {blue}#{user.username}{/blue}\n"
    end)
    |> Enum.join("")

    socket |> @socket.echo("Players online:\n#{usernames}")
    :ok
  end

  def run({:error, :bad_parse}, _session, %{socket: socket}) do
    socket |> @socket.echo("Unknown command")
    :ok
  end

  defp move_to(session, state = %{save: save, user: user}, room_id) do
    @room.leave(save.room_id, {session, user})

    save = %{save | room_id: room_id}
    state = %{state | save: save}

    @room.enter(room_id, {session, user})

    run({:look}, session, state)
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
