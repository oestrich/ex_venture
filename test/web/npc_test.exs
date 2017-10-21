defmodule Web.NPCTest do
  use Data.ModelCase

  alias Web.NPC
  alias Web.Room
  alias Web.Zone

  test "create a new npc" do
    params = %{
      "name" => "Bandit",
      "hostile" => "false",
      "level" => "1",
      "experience_points" => "124",
      "currency" => "10",
      "tags" => "enemy, dungeon",
      "stats" => %{
        health: 25,
        max_health: 25,
        strength: 10,
        intelligence: 10,
        dexterity: 10,
        skill_points: 10,
        max_skill_points: 10,
        move_points: 10,
        max_move_points: 10,
      } |> Poison.encode!(),
    }

    {:ok, npc} = NPC.create(params)

    assert npc.name == "Bandit"
    assert npc.tags == ["enemy", "dungeon"]
  end

  test "updating a npc" do
    npc = create_npc(%{name: "Fighter"})

    {:ok, zone} = Zone.create(zone_attributes(%{name: "The Forest"}))
    {:ok, room} = Room.create(zone, room_attributes(%{name: "Forest Path"}))
    {:ok, npc_spawner} = NPC.add_spawner(npc, %{zone_id: zone.id, room_id: room.id, spawn_interval: 15})

    {:ok, npc} = NPC.update(npc.id, %{name: "Barbarian"})

    assert npc.name == "Barbarian"

    state = Game.NPC._get_state(npc_spawner.id)
    assert state.npc.name == "Barbarian"
  end

  test "adding a new spawner" do
    {:ok, zone} = Zone.create(zone_attributes(%{name: "The Forest"}))
    {:ok, room} = Room.create(zone, room_attributes(%{name: "Forest Path"}))

    _state = Game.Zone._get_state(zone.id)

    npc = create_npc(%{name: "Fighter"})

    {:ok, npc_spawner} = NPC.add_spawner(npc, %{zone_id: zone.id, room_id: room.id, spawn_interval: 15})

    assert npc_spawner.zone_id == zone.id

    assert Game.Zone._get_state(zone.id)
    state = Game.NPC._get_state(npc_spawner.id)
    assert state.npc.name == "Fighter"
  end

  test "updating a spawner" do
    npc = create_npc(%{name: "Fighter"})

    {:ok, zone} = Zone.create(zone_attributes(%{name: "The Forest"}))
    {:ok, room} = Room.create(zone, room_attributes(%{name: "Forest Path"}))
    {:ok, npc_spawner} = NPC.add_spawner(npc, %{zone_id: zone.id, room_id: room.id, spawn_interval: 15})

    {:ok, npc_spawner} = NPC.update_spawner(npc_spawner.id, %{spawn_interval: 30})

    assert npc_spawner.spawn_interval == 30

    state = Game.NPC._get_state(npc_spawner.id)
    assert state.npc_spawner.spawn_interval == 30
  end

  test "deleting a spawner" do
    Process.flag(:trap_exit, true)

    npc = create_npc(%{name: "Fighter"})

    {:ok, zone} = Zone.create(zone_attributes(%{name: "The Forest"}))
    {:ok, room} = Room.create(zone, room_attributes(%{name: "Forest Path"}))
    {:ok, npc_spawner} = NPC.add_spawner(npc, %{zone_id: zone.id, room_id: room.id, spawn_interval: 15})

    assert Game.Zone._get_state(zone.id)
    npc_pid = Registry.whereis_name({Game.NPC.Registry, npc_spawner.id})
    Process.link(npc_pid)

    assert {:ok, _npc_spanwer} = NPC.delete_spawner(npc_spawner.id)

    assert_receive {:EXIT, ^npc_pid, _}
  end

  test "adding an item to an NPC" do
    npc = create_npc(%{name: "Fighter"})
    armor = create_item(%{name: "Armor"})

    {:ok, zone} = Zone.create(zone_attributes(%{name: "The Forest"}))
    {:ok, room} = Room.create(zone, room_attributes(%{name: "Forest Path"}))
    {:ok, npc_spawner} = NPC.add_spawner(npc, %{zone_id: zone.id, room_id: room.id, spawn_interval: 15})

    {:ok, npc} = NPC.add_item(npc, armor.id)

    assert npc.item_ids == [armor.id]

    state = Game.NPC._get_state(npc_spawner.id)
    assert state.npc.item_ids == [armor.id]
  end

  test "deleting an item npc an NPC" do
    npc = create_npc(%{name: "Fighter"})
    armor = create_item(%{name: "Armor"})

    {:ok, zone} = Zone.create(zone_attributes(%{name: "The Forest"}))
    {:ok, room} = Room.create(zone, room_attributes(%{name: "Forest Path"}))
    {:ok, npc_spawner} = NPC.add_spawner(npc, %{zone_id: zone.id, room_id: room.id, spawn_interval: 15})

    {:ok, npc} = NPC.add_item(npc, armor.id)
    {:ok, npc} = NPC.delete_item(npc, armor.id |> Integer.to_string())

    assert npc.item_ids == []

    state = Game.NPC._get_state(npc_spawner.id)
    assert state.npc.item_ids == []
  end
end
