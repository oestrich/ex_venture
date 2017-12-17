defmodule Game.Command.Look do
  @moduledoc """
  The "look" command
  """

  use Game.Command
  use Game.Zone

  alias Data.Exit
  alias Game.Items
  alias Game.Session.GMCP

  commands ["look at", {"look", ["l"]}]

  @impl Game.Command
  def help(:topic), do: "Look"
  def help(:short), do: "Look around the room"
  def help(:full) do
    """
    View information about the room you are in.

    Example:
    [ ] > {white}look{/white}
    """
  end

  @doc """
  Look around the current room
  """
  @impl Game.Command
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({}, _session, state = %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    mini_map = room.zone_id |> @zone.map({room.x, room.y, room.map_layer}, mini: true)
    room_map =
      mini_map
      |> String.split("\n")
      |> Enum.slice(2..-1)
      |> Enum.join("\n")

    items = room_items(room)
    state |> GMCP.room(room, items)
    socket |> @socket.echo(Format.room(room, items, room_map))
    state |> GMCP.map(mini_map)

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

    item =
      room.items
      |> Enum.find_value(fn (instance) ->
        item = Items.item(instance)
        if Game.Item.matches_lookup?(item, item_name), do: item
      end)

    case item do
      nil -> nil
      item ->
        socket |> @socket.echo(Format.item(item))
    end

    :ok
  end

  defp room_items(%{items: nil}), do: []
  defp room_items(%{items: items}), do: Enum.map(items, &Items.item/1)
end
