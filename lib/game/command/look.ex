defmodule Game.Command.Look do
  @moduledoc """
  The "look" command
  """

  use Game.Command
  use Game.Zone

  alias Data.Exit
  alias Game.Session.GMCP

  @commands ["look at", "look"]
  @aliases ["l"]

  @short_help "Look around the room"
  @full_help """
  View information about the room you are in.

  Example:
  [ ] > {white}look{/white}
  """

  @doc """
  Look around the current room
  """
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({}, _session, state = %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    state |> GMCP.room(room)
    socket |> @socket.echo(Format.room(room))

    map = room.zone_id |> @zone.map({room.x, room.y, room.map_layer}, mini: true)
    state |> GMCP.map(map)

    :ok
  end
  def run({direction}, _, %{socket: socket, save: %{room_id: room_id}}) when direction in ["north", "east", "south", "west"] do
    room = @room.look(room_id)

    id_key = String.to_atom("#{direction}_id")
    case room |> Exit.exit_to(direction) do
      %{^id_key => room_id} ->
        room = @room.look(room_id)
        socket |> @socket.echo(Format.peak_room(room, direction))
      _ -> nil
    end

    :ok
  end
  def run({item_name}, _session, %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)

    case Enum.find(room.items, &(Game.Item.matches_lookup?(&1, item_name))) do
      nil -> nil
      item -> socket |> @socket.echo(Format.item(item))
    end

    :ok
  end
end
