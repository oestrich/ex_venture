defmodule Game.Format.Rooms do
  @moduledoc """
  Format functions for rooms
  """

  import Game.Format.Context

  alias Data.Exit
  alias Data.Room
  alias Game.Door
  alias Game.Format
  alias Game.Format.NPCs, as: FormatNPCs

  @doc """
  Display a room's name
  """
  def room_name(room) do
    "{room}#{room.name}{/room}"
  end

  @doc """
  Display a zone's name
  """
  def zone_name(zone) do
    "{zone}#{zone.name}{/zone}"
  end

  @doc """
  Format full text for a room
  """
  @spec room(Room.t(), [Item.t()], Map.t()) :: String.t()
  def room(room, items, map) do
    """
    #{room_name(room)}
    #{Format.underline(room.name)}
    #{room_description(room)}\n
    #{map}

    #{who_is_here(room)}

    #{maybe_exits(room)}#{maybe_items(room, items)}#{shops(room)}
    """
    |> String.trim()
  end

  @doc """
  Template a room's description
  """
  def room_description(room) do
    description = room_description_with_features(room)

    context =
      context()
      |> assign(:room, room_name(room))
      |> assign(:zone, zone_name(room.zone))
      |> assign(:features, Enum.join(features(room.features), " "))

    context =
      Enum.reduce(room.features, context, fn room_feature, context ->
        assign(context, room_feature.key, feature(room_feature))
      end)

    Format.template(context, Format.resources(description))
  end

  defp room_description_with_features(room) do
    contains_features? = String.contains?(room.description, "[features]")
    contains_sub_features? = Enum.any?(room.features, fn feature ->
      String.contains?(room.description, "[#{feature.key}]")
    end)

    case contains_features? || contains_sub_features? do
      true ->
        room.description

      false ->
        "#{room.description} [features]"
    end
  end

  @doc """
  Display a room's feature
  """
  def feature(feature) do
    String.replace(feature.short_description, feature.key, "{white}#{feature.key}{/white}")
  end

  @doc """
  Display room features
  """
  def features(features) do
    Enum.map(features, &feature/1)
  end

  @doc """
  Peak at a room from the room you're in

  Example:

    iex> Rooms.peak_room(%{name: "Hallway"}, "north")
    "{room}Hallway{/room} is north."
  """
  @spec peak_room(Room.t(), String.t()) :: String.t()
  def peak_room(room, direction) do
    "#{room_name(room)} is #{direction}."
  end

  @doc """
  Output for an overworld look
  """
  @spec overworld_room(Overworld.t(), String.t()) :: String.t()
  def overworld_room(room, map) do
    """
    {bold}#{map}{/bold}

    #{who_is_here(room)}

    #{maybe_exits(room)}
    """
    |> String.trim()
  end

  defp maybe_exits(room) do
    case room |> Room.exits() do
      [] ->
        ""

      _ ->
        "Exits: #{exits(room)}\n"
    end
  end

  defp exits(room) do
    room
    |> Room.exits()
    |> Enum.sort()
    |> Enum.map(fn direction ->
      case Exit.exit_to(room, direction) do
        %{door_id: door_id, has_door: true} ->
          "{exit}#{direction}{/exit} (#{Door.get(door_id)})"

        _ ->
          "{exit}#{direction}{/exit}"
      end
    end)
    |> Enum.join(", ")
  end

  @doc """
  Format full text for who is in the room

  Example:

      iex> Rooms.who_is_here(%{players: [%{name: "Mordred"}], npcs: [%{name: "Arthur", extra: %{status_line: "[name] is here."}}]})
      "{npc}Arthur{/npc} is here.\\n{player}Mordred{/player} is here."
  """
  def who_is_here(room) do
    [npcs(room), players(room)]
    |> Enum.reject(fn line -> line == "" end)
    |> Enum.join("\n")
  end

  @doc """
  Format Player text for who is in the room

  Example:

      iex> Rooms.players(%{players: [%{name: "Mordred"}, %{name: "Arthur"}]})
      "{player}Mordred{/player} is here.\\n{player}Arthur{/player} is here."
  """
  @spec players(Room.t()) :: String.t()
  def players(%{players: players}) do
    players
    |> Enum.map(fn player -> "#{Format.player_name(player)} is here." end)
    |> Enum.join("\n")
  end

  def players(_), do: ""

  @doc """
  Format NPC text for who is in the room

  Example:

      iex> mordred = %{name: "Mordred", extra: %{status_line: "[name] is in the room."}}
      iex> arthur = %{name: "Arthur", extra: %{status_line: "[name] is here."}}
      iex> Rooms.npcs(%{npcs: [mordred, arthur]})
      "{npc}Mordred{/npc} is in the room.\\n{npc}Arthur{/npc} is here."
  """
  @spec npcs(Room.t()) :: String.t()
  def npcs(%{npcs: npcs}) do
    npcs
    |> Enum.map(&FormatNPCs.npc_status/1)
    |> Enum.join("\n")
  end

  def npcs(_), do: ""

  @doc """
  Maybe display items
  """
  def maybe_items(room, items) do
    case Enum.empty?(items) and room.currency == 0 do
      true ->
        ""

      false ->
        "Items: #{items(room, items)}\n"
    end
  end

  @doc """
  Format items for a room
  """
  def items(room, items) when is_list(items) do
    items = items |> Enum.map(&Format.item_name/1)

    (items ++ [Format.currency(room)])
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(", ")
  end

  def items(_, _), do: ""

  @doc """
  Format Shop text for shops in the room

  Example:

      iex> Rooms.shops(%{shops: [%{name: "Hole in the Wall"}]})
      "Shops: {shop}Hole in the Wall{/shop}\\n"

      iex> Rooms.shops(%{shops: [%{name: "Hole in the Wall"}]}, label: false)
      "  - {shop}Hole in the Wall{/shop}"
  """
  @spec shops(Room.t()) :: String.t()
  def shops(room, opts \\ [])
  def shops(%{shops: []}, _opts), do: ""

  def shops(%{shops: shops}, label: false) do
    shops
    |> Enum.map(fn shop -> "  - #{Format.shop_name(shop)}" end)
    |> Enum.join(", ")
  end

  def shops(%{shops: shops}, _) do
    shops =
      shops
      |> Enum.map(&Format.shop_name/1)
      |> Enum.join(", ")

    "Shops: #{shops}\n"
  end

  def shops(_, _), do: ""
end
