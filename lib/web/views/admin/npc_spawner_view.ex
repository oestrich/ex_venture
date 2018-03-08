defmodule Web.Admin.NPCSpawnerView do
  use Web, :view

  alias Web.Admin.NPCView
  alias Web.Zone

  def display_full_form?(conn) do
    conn.params
    |> Map.get("npc_spawner", %{})
    |> Map.has_key?("zone_id")
  end

  def room_exits(zone) do
    Enum.map(zone.rooms, &{"#{&1.id} - #{&1.name}", &1.id})
  end

  def npc_name(npc_spawner) do
    if NPCView.custom_name?(npc_spawner) do
      npc_spawner.name
    else
      npc_spawner.npc.name
    end
  end
end
