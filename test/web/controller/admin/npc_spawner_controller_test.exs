defmodule Web.Controller.NPCSpawnerControllerTest do
  use Web.AuthConnCase

  setup do
    zone = create_zone()
    room = create_room(zone, %{x: 1, y: 1})
    npc = create_npc()

    %{npc: npc, zone: zone, room: room}
  end

  test "create a new spawner", %{conn: conn, npc: npc, zone: zone, room: room} do
    conn = post conn, npc_spawner_path(conn, :create, npc.id), npc_spawner: %{zone_id: zone.id, room_id: room.id, spawn_interval: 15}
    assert html_response(conn, 302)
  end
end
