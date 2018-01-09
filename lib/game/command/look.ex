defmodule Game.Command.Look do
  @moduledoc """
  The "look" command
  """

  use Game.Command
  use Game.Zone

  alias Data.Exit
  alias Game.Item
  alias Game.Items
  alias Game.Session.GMCP
  alias Game.Utility

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
  def run({name}, _session, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)

    room
    |> maybe_look_item(name, state)
    |> maybe_look_npc(name, state)

    :ok
  end

  defp room_items(%{items: nil}), do: []
  defp room_items(%{items: items}), do: Enum.map(items, &Items.item/1)

  defp maybe_look_item(room, item_name, %{socket: socket}) do
    item =
      room.items
      |> Items.items_keep_instance()
      |> Item.find_item(item_name)

    case item do
      nil -> room
      {_instance, item} ->
        socket |> @socket.echo(Format.item(item))
        :ok
    end
  end

  defp maybe_look_npc(:ok, _name, _state), do: :ok
  defp maybe_look_npc(room, npc_name, %{socket: socket}) do
    npc = room.npcs |> Enum.find(&(Utility.matches?(&1, npc_name)))

    case npc do
      nil -> room
      npc ->
        socket |> @socket.echo(Format.npc_full(npc))
        :ok
    end
  end
end
