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

  commands(["look at", {"look", ["l"]}])

  @impl Game.Command
  def help(:topic), do: "Look"
  def help(:short), do: "Look around the room"

  def help(:full) do
    """
    View information about the room you are in.

    Example:
    [ ] > {white}look{/white}
    [ ] > {white}look at guard{/white}
    [ ] > {white}look at player{/white}
    [ ] > {white}look at sword{/white}
    [ ] > {white}look north{/white}
    """
  end

  @impl Game.Command
  @doc """
  Look around the current room
  """
  def run(command, state)

  def run({}, state = %{socket: socket, save: %{room_id: room_id}}) do
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

  def run({direction}, %{socket: socket, save: %{room_id: room_id}})
      when direction in ["north", "east", "south", "west"] do
    room = @room.look(room_id)

    id_key = String.to_atom("#{direction}_id")

    case room |> Exit.exit_to(direction) do
      %{^id_key => room_id} ->
        room = @room.look(room_id)
        socket |> @socket.echo(Format.peak_room(room, direction))

      _ ->
        nil
    end

    :ok
  end

  def run({name}, state = %{save: %{room_id: room_id}}) do
    room = @room.look(room_id)

    room
    |> maybe_look_item(name, state)
    |> maybe_look_npc(name, state)
    |> maybe_look_player(name, state)
    |> could_not_find(name, state)

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
      nil ->
        room

      {_instance, item} ->
        socket |> @socket.echo(Format.item(item))
        :ok
    end
  end

  defp maybe_look_npc(:ok, _name, _state), do: :ok

  defp maybe_look_npc(room, npc_name, %{socket: socket}) do
    npc = room.npcs |> Enum.find(&Utility.matches?(&1, npc_name))

    case npc do
      nil ->
        room

      npc ->
        socket |> @socket.echo(Format.npc_full(npc))
        :ok
    end
  end

  defp maybe_look_player(:ok, _name, _state), do: :ok

  defp maybe_look_player(room, player_name, %{socket: socket}) do
    player = room.players |> Enum.find(&Utility.matches?(&1, player_name))

    case player do
      nil ->
        room

      player ->
        socket |> @socket.echo(Format.player_full(player))
        :ok
    end
  end

  defp could_not_find(:ok, _name, _state), do: :ok

  defp could_not_find(_, name, %{socket: socket}) do
    socket |> @socket.echo("Could not find \"#{name}\"")
    :ok
  end
end
