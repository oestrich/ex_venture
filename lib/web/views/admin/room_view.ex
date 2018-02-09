defmodule Web.Admin.RoomView do
  use Web, :view
  use Game.Currency

  alias Data.Exit
  alias Data.Room
  alias Game.Items

  def room_select(%{rooms: rooms}) do
    rooms |> Enum.map(&{&1.name, &1.id})
  end

  def has_exit?(room, direction) do
    get_exit(room, direction) != nil
  end

  def display_exit(room, direction) do
    capital_direction =
      direction
      |> to_string()
      |> String.capitalize()

    room_name = get_exit(room, direction).name

    door =
      case room |> exit_has_door?(direction) do
        true -> " - Door"
        false -> ""
      end

    "#{capital_direction} (#{room_name}#{door})"
  end

  def exit_has_door?(room, direction) do
    room
    |> Exit.exit_to(direction)
    |> Map.get(:has_door)
  end

  def get_exit(room, direction) do
    case room |> Exit.exit_to(direction) do
      nil -> nil
      room_exit -> Map.get(room_exit, direction)
    end
  end

  def keep_newlines(string) do
    string
    |> String.replace("\n", "<br />")
    |> raw()
  end
end
