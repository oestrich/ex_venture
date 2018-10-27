defmodule Game.Command.Look do
  @moduledoc """
  The "look" command
  """

  use Game.Command
  use Game.Zone

  alias Data.Exit
  alias Game.Environment
  alias Game.Environment.State.Overworld
  alias Game.Environment.State.Room
  alias Game.Format.Items, as: FormatItems
  alias Game.Format.Players, as: FormatPlayers
  alias Game.Format.NPCs, as: FormatNPCs
  alias Game.Format.Rooms, as: FormatRooms
  alias Game.Hint
  alias Game.Item
  alias Game.Items
  alias Game.Quest
  alias Game.Session.GMCP
  alias Game.Utility

  commands(["look at", {"look", ["l"]}], parse: false)

  @impl Game.Command
  def help(:topic), do: "Look"
  def help(:short), do: "Look around the room"

  def help(:full) do
    """
    View information about the room you are in. You can look at characters in
    the same room as you, items, as well as exit directions.

    Room's may also have highlighted words that you can look at to get further
    detail about that feature of the room.

    Example:
    [ ] > {command}look{/command}
    [ ] > {command}look at guard{/command}
    [ ] > {command}look at player{/command}
    [ ] > {command}look at sword{/command}
    [ ] > {command}look north{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Look.parse("look")
      {}

      iex> Game.Command.Look.parse("look east")
      {:direction, "east"}

      iex> Game.Command.Look.parse("look feature")
      {:other, "feature"}

      iex> Game.Command.Look.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  @spec parse(String.t()) :: {any()}
  def parse(command)
  def parse("look"), do: {}
  def parse("l"), do: {}
  def parse("look at " <> string), do: parse_direction_or_feature(string)
  def parse("look " <> string), do: parse_direction_or_feature(string)
  def parse("l " <> string), do: parse_direction_or_feature(string)

  defp parse_direction_or_feature(string) do
    case string in Exit.directions() do
      true ->
        {:direction, string}

      false ->
        {:other, string}
    end
  end

  @impl Game.Command
  @doc """
  Look around the current room
  """
  def run(command, state)

  def run({}, state = %{save: save}) do
    with {:ok, room} <- @environment.look(save.room_id) do
      state |> look_room(room)
    else
      {:error, :room_offline} ->
        {:error, :room_offline}
    end
  end

  def run({:direction, direction}, state = %{save: save}) do
    with :room <- Environment.room_type(save.room_id),
         {:ok, room} <- @environment.look(save.room_id),
         %{finish_id: room_id} <- Exit.exit_to(room, direction),
         {:ok, room} <- @environment.look(room_id) do
      state.socket |> @socket.echo(FormatRooms.peak_room(room, direction))
    else
      :overworld ->
        :ok

      {:error, :room_offline} ->
        {:error, :room_offline}

      _ ->
        message = gettext("Nothing can be seen %{direction}.", direction: direction)
        state.socket |> @socket.echo(message)
    end
  end

  def run({:other, name}, state = %{save: %{room_id: room_id}}) do
    {:ok, room} = @environment.look(room_id)

    room
    |> maybe_look_item(name, state)
    |> maybe_look_npc(name, state)
    |> maybe_look_player(name, state)
    |> maybe_look_feature(name, state)
    |> could_not_find(name, state)
  end

  defp look_room(state, room = %Room{}) do
    mini_map = room.zone_id |> @zone.map({room.x, room.y, room.map_layer}, mini: true)

    room_map =
      mini_map
      |> String.split("\n")
      |> Enum.slice(2..-1)
      |> Enum.join("\n")

    items = room_items(room)
    room = remove_yourself(room, state)

    state |> GMCP.room(room, items)
    state |> GMCP.map(mini_map)

    state.socket |> @socket.echo(FormatRooms.room(room, items, room_map))

    maybe_hint_quest(state, room)
  end

  defp look_room(state, room = %Overworld{}) do
    mini_map = room.zone_id |> @zone.map({room.x, room.y})

    state |> GMCP.map(mini_map)

    room = remove_yourself(room, state)
    state.socket |> @socket.echo(FormatRooms.overworld_room(room, mini_map))
  end

  defp maybe_hint_quest(state, room) do
    npc_ids = Enum.map(room.npcs, & &1.extra.original_id)

    quest =
      state.user
      |> Quest.for()
      |> Quest.filter_active_quests_for_room(npc_ids)
      |> Quest.find_quest_for_ready_to_complete(state.save)

    case quest do
      {:ok, quest} ->
        Hint.gate(state, "quests.complete", %{quest_id: quest.quest_id})

      {:error, :none} ->
        :ok
    end
  end

  defp remove_yourself(room, state) do
    players = Enum.reject(room.players, &(&1.id == state.user.id))
    %{room | players: players}
  end

  defp room_items(%{items: nil}), do: []
  defp room_items(%{items: items}), do: Enum.map(items, &Items.item/1)

  defp maybe_look_item(room = %Overworld{}, _item_name, _state), do: room

  defp maybe_look_item(room, item_name, %{socket: socket}) do
    item =
      room.items
      |> Items.items_keep_instance()
      |> Item.find_item(item_name)

    case item do
      {:error, :not_found} ->
        room

      {:ok, {_instance, item}} ->
        socket |> @socket.echo(FormatItems.item(item))
    end
  end

  defp maybe_look_npc(:ok, _name, _state), do: :ok

  defp maybe_look_npc(room, npc_name, %{socket: socket}) do
    npc = room.npcs |> Enum.find(&Utility.matches?(&1, npc_name))

    case npc do
      nil ->
        room

      npc ->
        socket |> @socket.echo(FormatNPCs.npc_full(npc))
    end
  end

  defp maybe_look_player(:ok, _name, _state), do: :ok

  defp maybe_look_player(room, player_name, %{socket: socket}) do
    player = room.players |> Enum.find(&Utility.matches?(&1, player_name))

    case player do
      nil ->
        room

      player ->
        socket |> @socket.echo(FormatPlayers.player_full(player))
    end
  end

  defp maybe_look_feature(:ok, _name, _state), do: :ok

  defp maybe_look_feature(room = %Overworld{}, _item_name, _state), do: room

  defp maybe_look_feature(room, key, %{socket: socket}) do
    feature = room.features |> Enum.find(&Utility.matches?(&1.key, key))

    case feature do
      nil ->
        room

      feature ->
        socket |> @socket.echo(feature.description)
    end
  end

  defp could_not_find(:ok, _name, _state), do: :ok

  defp could_not_find(_, name, %{socket: socket}) do
    socket |> @socket.echo(gettext("Could not find \"%{name}\".", name: name))
  end
end
