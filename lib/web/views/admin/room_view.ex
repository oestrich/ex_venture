defmodule Web.Admin.RoomView do
  use Web, :view

  alias Data.Exit
  alias Game.Items

  def room_select(%{rooms: rooms}) do
    rooms |> Enum.map(&({&1.name, &1.id}))
  end

  def has_exit?(room, direction) do
    get_exit(room, direction) != nil
  end

  def get_exit(room, direction) do
    case room |> Exit.exit_to(direction) do
      nil -> nil
      room_exit -> Map.get(room_exit, direction)
    end
  end
end
