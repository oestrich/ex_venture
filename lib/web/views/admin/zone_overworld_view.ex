defmodule Web.Admin.ZoneOverworldView do
  use Web, :view

  alias Data.Exit
  alias Web.Zone

  def render("exits.json", %{exits: exits}) do
    render_many(exits, __MODULE__, "exit.json", as: :room_exit)
  end

  def render("exit.json", %{room_exit: room_exit}) do
    Map.take(room_exit, [:id, :direction, :start_overworld_id, :finish_room_id])
  end

  def room_exits(zone) do
    zone
    |> Zone.room_exits()
    |> Enum.map(fn {zone_name, rooms} ->
      rooms = Enum.map(rooms, fn {name, id} ->
        %{id: id, name: name}
      end)

      %{name: zone_name, rooms: rooms}
    end)
  end
end
