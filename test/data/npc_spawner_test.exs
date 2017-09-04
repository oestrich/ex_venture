defmodule Data.NPCSpawnerTest do
  use Data.ModelCase

  alias Data.NPCSpawner

  test "valdiates zone and room match up" do
    npc = create_npc()

    zone = create_zone()
    room = create_room(zone)

    changeset = %NPCSpawner{} |> NPCSpawner.changeset(%{npc_id: npc.id, zone_id: zone.id, room_id: room.id, spawn_interval: 15})
    assert changeset.valid?

    room = create_room(create_zone())

    changeset = %NPCSpawner{} |> NPCSpawner.changeset(%{npc_id: npc.id, zone_id: zone.id, room_id: room.id, spawn_interval: 15})
    refute changeset.valid?
  end
end
