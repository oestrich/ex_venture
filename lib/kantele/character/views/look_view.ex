defmodule Kantele.Character.LookView do
  use Kalevala.Character.View

  alias Kalevala.Character.Conn.EventText
  alias Kantele.Character.CharacterView
  alias Kantele.Character.ItemView

  def render("look", %{room: room, characters: characters, item_instances: item_instances}) do
    %EventText{
      topic: "Room.Info",
      data: %{
        characters: characters,
        description: render("_description", %{room: room}),
        exits: Enum.map(room.exits, fn room_exit -> room_exit.exit_name end),
        item_instances: item_instances,
        name: room.name,
        x: room.x,
        y: room.y,
        z: room.z
      },
      text: render("look.text", %{room: room})
    }
  end

  def render("mini_map", %{mini_map: mini_map}) do
    %EventText{
      topic: "Zone.MiniMap",
      data: %{
        mini_map: mini_map.cells
      },
      text: [mini_map.display, "\n"]
    }
  end

  def render("look.extra", %{room: room, characters: characters, item_instances: item_instances}) do
    %EventText{
      topic: "Room.Info.Extra",
      data: %{},
      text:
        render("look.extra.text", %{
          characters: characters,
          item_instances: item_instances,
          room: room
        })
    }
  end

  def render("look.text", %{room: room}) do
    ~E"""
    {room-title id="<%= room.id %>" x="<%= to_string(room.x) %>" y="<%= to_string(room.y) %>" z="<%= to_string(room.z) %>"}<%= room.name %>{/room-title}
    <%= render("_description", %{room: room}) %>
    """
  end

  def render("look.extra.text", %{
        characters: characters,
        item_instances: item_instances,
        room: room
      }) do
    lines = [
      render("_items", %{item_instances: item_instances}),
      render("_exits", %{room: room}),
      render("_characters", %{characters: characters})
    ]

    lines
    |> Enum.reject(&is_nil/1)
    |> Enum.map(fn line ->
      [line, "\n"]
    end)
  end

  def render("_description", %{room: room}) do
    features =
      Enum.map(room.features, fn feature ->
        description = String.split(feature.short_description, feature.keyword)
        View.join(description, [~s({color foreground="white"}), feature.keyword, "{/color}"])
      end)

    description = [room.description] ++ features

    description
    |> Enum.reject(fn line -> line == "" end)
    |> View.join(" ")
  end

  def render("_exits", %{room: room}) do
    exits =
      room.exits
      |> Enum.map(fn room_exit ->
        ~i({exit name="#{room_exit.exit_name}"}#{room_exit.exit_name}{/exit})
      end)
      |> View.join(" ")

    View.join(["Exits:", exits], " ")
  end

  def render("_characters", %{characters: []}), do: nil

  def render("_characters", %{characters: characters}) do
    characters =
      characters
      |> Enum.map(&render("_character", %{character: &1}))
      |> View.join("\n")

    View.join(["You see:", characters], "\n")
  end

  def render("_character", %{character: character}) do
    ~i(- #{CharacterView.render("name", %{character: character})})
  end

  def render("_items", %{item_instances: []}), do: nil

  def render("_items", %{item_instances: item_instances}) do
    items =
      item_instances
      |> Enum.map(&ItemView.render("name", %{item_instance: &1, context: :room}))
      |> View.join(", ")

    View.join(["Items:", items], " ")
  end
end
