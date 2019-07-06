defmodule Game.Format.Rooms do
  @moduledoc """
  Format functions for rooms
  """

  import Game.Format.Context

  alias Data.Exit
  alias Data.Room
  alias Game.Door
  alias Game.DoorLock
  alias Game.Format
  alias Game.Format.NPCs, as: FormatNPCs
  alias Game.Format.Proficiencies, as: FormatProficiencies

  @doc """
  Display a room's name
  """
  def room_name(room) do
    context()
    |> assign(:name, room.name)
    |> Format.template("{room}[name]{/room}")
  end

  @doc """
  Display a zone's name
  """
  def zone_name(zone) do
    context()
    |> assign(:name, zone.name)
    |> Format.template("{zone}[name]{/zone}")
  end

  @doc """
  Format full text for a room
  """
  @spec room(Room.t(), [Item.t()], Map.t()) :: String.t()
  def room(room, items, map) do
    context()
    |> assign(:name, room_name(room))
    |> assign(:underline, Format.underline(room.name))
    |> assign(:description, room_description(room))
    |> assign(:map, map)
    |> assign(:who, who_is_here(room))
    |> assign(:exits, maybe_exits(room))
    |> assign(:items, maybe_items(room, items))
    |> assign(:shops, shops(room))
    |> Format.template(template("room"))
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

    contains_sub_features? =
      Enum.any?(room.features, fn feature ->
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

    iex> Rooms.peak_room(%{direction: "north", requirements: []}, %{name: "Hallway"})
    "{room}Hallway{/room} is north."
  """
  def peak_room(room_exit, room) do
    context()
    |> assign(:name, room_name(room))
    |> assign(:direction, room_exit.direction)
    |> assign(:requirements, exit_requirements(room_exit))
    |> Format.template("[name] is [direction].[requirements]")
  end

  defp exit_requirements(%{requirements: []}), do: nil

  defp exit_requirements(room_exit) do
    context()
    |> assign_many(:requirements, room_exit.requirements, &render_requirement/1)
    |> Format.template("\n\nRequirements:\n[requirements]")
  end

  def render_requirement(requirement) do
    context()
    |> assign(:name, FormatProficiencies.name(requirement))
    |> assign(:rank, requirement.ranks)
    |> Format.template("  - [name] [rank]")
  end

  @doc """
  Output for an overworld look
  """
  @spec overworld_room(Overworld.t(), String.t()) :: String.t()
  def overworld_room(room, map) do
    context()
    |> assign(:map, map)
    |> assign(:who, who_is_here(room))
    |> assign(:exits, maybe_exits(room))
    |> Format.template(template("overworld"))
  end

  defp maybe_exits(room) do
    case room |> Room.exits() do
      [] ->
        nil

      directions ->
        directions = Enum.sort(directions)

        context()
        |> assign_many(:exits, directions, &render_exit(room, &1), joiner: ", ")
        |> Format.template("Exits: [exits]")
    end
  end

  defp render_exit(room, direction) do
    room_exit = Exit.exit_to(room, direction)

    context()
    |> assign(:direction, direction)
    |> assign(:door_state, door_state(room_exit))
    |> assign(:requirements, exit_requirements_hint(room_exit))
    |> Format.template("{exit}[direction]{/exit}[requirements][ door_state]")
  end

  defp door_state(room_exit) do
    case room_exit.has_door do
      true ->
        door_state = if Door.closed?(room_exit.door_id) do
          if room_exit.has_lock && DoorLock.locked?(room_exit.door_id) do
            "locked"
          else
            "closed"
          end
        else
          "open"
        end

        context()
        |> assign(:door_state, door_state)
        |> Format.template("([door_state])")

      false ->
        nil
    end
  end

  defp exit_requirements_hint(room_exit) do
    case Enum.empty?(room_exit.requirements) do
      true ->
        nil

      false ->
        context()
        |> Format.template("{white}*{/white}")
    end
  end

  @doc """
  Format full text for who is in the room

  Example:

      iex> Rooms.who_is_here(%{players: [%{name: "Mordred"}], npcs: [%{name: "Arthur", extra: %{status_line: "[name] is here."}}]})
      "{player}Mordred{/player} is here.\\n{npc}Arthur{/npc} is here."
  """
  def who_is_here(room) do
    context()
    |> assign_many(:players, room.players, &player_line/1)
    |> assign_many(:npcs, room.npcs, &FormatNPCs.npc_status/1)
    |> Format.template("[players\n][npcs]")
  end

  @doc """
  Format a player's status line
  """
  def player_line(player) do
    context()
    |> assign(:name, Format.player_name(player))
    |> Format.template("[name] is here.")
  end

  @doc """
  Maybe display items
  """
  def maybe_items(room, items) do
    case Enum.empty?(items) and room.currency == 0 do
      true ->
        nil

      false ->
        items = Enum.map(items, &Format.item_name/1)
        items = items ++ [Format.currency(room)]
        items = Enum.reject(items, &(&1 == ""))

        context()
        |> assign_many(:items, items, &(&1), joiner: ", ")
        |> Format.template("Items: [items]")
    end
  end

  @doc """
  Format Shop text for shops in the room
  """
  def shops(room) do
    case Enum.empty?(room.shops) do
      true ->
        nil

      false ->
        context()
        |> assign_many(:shops, room.shops, &Format.shop_name/1, joiner: ", ")
        |> Format.template("Shops: [shops]")
    end
  end

  def list_shops(room) do
    context()
    |> assign_many(:shops, room.shops, &shop_line/1)
    |> Format.template("Shops around you:\n[shops]")
  end

  def shop_line(shop) do
    context()
    |> assign(:name, Format.shop_name(shop))
    |> Format.template("  - [name]")
  end

  def template("room") do
    """
    [name]
    [underline]
    [description]

    [map]

    [who]

    [exits]
    [items]
    [shops]
    """
  end

  def template("overworld") do
    """
    {bold}[map]{/bold}

    [who]

    [exits]
    """
  end
end
