defmodule Web.Admin.NPCSpawnerView do
  use Web, :view

  alias Web.Zone

  def display_full_form?(conn) do
    conn.params
    |> Map.get("npc_spawner", %{})
    |> Map.has_key?("zone_id")
  end

  def room_exits(zone) do
    Enum.map(zone.rooms, &({"#{&1.id} - #{&1.name}", &1.id}))
  end
end
