defmodule Web.Admin.RoomView do
  use Web, :view
  use Game.Currency

  alias Data.Exit
  alias Data.Room
  alias Game.Features
  alias Game.Format
  alias Game.Format.Rooms, as: FormatRooms
  alias Game.Items
  alias Web.Color
  alias Web.Help
  alias Web.Admin.SharedView

  def room_select(%{rooms: rooms}) do
    rooms |> Enum.map(&{&1.name, &1.id})
  end

  def display_direction(direction) do
    direction
    |> to_string()
    |> String.capitalize()
  end

  def display_exit(room, direction) do
    room_name = get_exit(room, direction).name

    door =
      case room |> exit_has_door?(direction) do
        true -> " - Door"
        false -> ""
      end

    "#{display_direction(direction)} (#{room_name}#{door})"
  end

  def exit_has_door?(room, direction) do
    room
    |> Exit.exit_to(direction)
    |> Map.get(:has_door)
  end

  def get_exit(room, direction) do
    case room |> Exit.exit_to(direction) do
      nil ->
        nil

      room_exit ->
        room_exit.finish_room
    end
  end

  def keep_newlines(string) do
    string
    |> String.replace("\n", "<br />")
    |> raw()
  end

  def items(room, conn) do
    items =
      room.items
      |> Items.items()
      |> Enum.map(fn item ->
        content_tag :span, class: "cyan" do
          link(item.name, to: item_path(conn, :show, item.id))
        end
      end)

    add_new =
      content_tag :span, class: "cyan" do
        link(
          "Add Item",
          to: room_room_item_path(conn, :new, room.id, spawn: false),
          data: [toggle: "tooltip"],
          title: Help.get("room.items")
        )
      end

    currency =
      content_tag :span, class: "cyan" do
        "#{room.currency} #{currency()}"
      end

    [items | [currency | [add_new]]]
    |> List.flatten()
    |> Enum.map(&safe_to_string/1)
    |> Enum.join(", ")
    |> raw()
  end

  def who(room, conn) do
    room.npc_spawners
    |> Enum.map(fn npc_spawner ->
      content_tag :span, class: "yellow" do
        link(npc_spawner.npc.name, to: npc_path(conn, :show, npc_spawner.npc_id))
      end
    end)
    |> Enum.map(&safe_to_string/1)
    |> Enum.join(", ")
    |> raw()
  end

  def description(room) do
    features = room.features ++ Features.features(room.feature_ids)
    room = Map.put(room, :features, features)

    room
    |> FormatRooms.room_description()
    |> Format.wrap()
    |> Color.format()
    |> raw()
  end

  def listen(%{listen: nil}), do: ""

  def listen(room) do
    text =
      room.listen
      |> Format.wrap()
      |> Color.format()
      |> raw()

    ["\n", content_tag(:span, "You hear:", class: "white"), "\n", text]
  end
end
