defmodule Web.Admin.ZoneOverworldView do
  use Web, :view

  alias Data.Exit
  alias Web.Zone

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
