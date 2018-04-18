defmodule Web.NPCTest do
  use Data.ModelCase

  alias Web.NPC
  alias Web.Room
  alias Web.Zone

  test "create a new npc" do
    params = %{
      "name" => "Bandit",
      "level" => "1",
      "experience_points" => "124",
      "currency" => "10",
      "tags" => "enemy, dungeon",
      "events" => [
        %{"type" => "room/entered", "action" => %{"type" => "say", "message" => "Hi"}},
      ] |> Poison.encode!(),
      "script" => [
        %{"key" => "start", "message" => "Hi"},
      ] |> Poison.encode!(),
      "stats" => %{
        health_points: 25,
        max_health_points: 25,
        strength: 10,
        dexterity: 10,
        constitution: 13,
        intelligence: 10,
        wisdom: 10,
        skill_points: 10,
        max_skill_points: 10,
        move_points: 10,
        max_move_points: 10,
      } |> Poison.encode!(),
    }

    {:ok, npc} = NPC.create(params)

    assert npc.name == "Bandit"
    assert npc.tags == ["enemy", "dungeon"]
    assert npc.events |> length() == 1
    assert npc.script |> length() == 1
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
    npc_pid = Swarm.whereis_name({Game.NPC, npc_spawner.id})
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

    {:ok, npc_item} = NPC.add_item(npc, %{"item_id" => armor.id, "drop_rate" => 10})

    assert npc_item.drop_rate == 10

    npc = NPC.get(npc.id)
    assert npc.npc_items |> length() == 1

    state = Game.NPC._get_state(npc_spawner.id)
    assert state.npc.npc_items |> length() == 1
  end

  test "updating an item on an npc" do
    npc = create_npc(%{name: "Fighter"})
    armor = create_item(%{name: "Armor"})

    {:ok, zone} = Zone.create(zone_attributes(%{name: "The Forest"}))
    {:ok, room} = Room.create(zone, room_attributes(%{name: "Forest Path"}))
    {:ok, npc_spawner} = NPC.add_spawner(npc, %{zone_id: zone.id, room_id: room.id, spawn_interval: 15})

    {:ok, npc_item} = NPC.add_item(npc, %{"item_id" => armor.id, "drop_rate" => 10})
    {:ok, npc_item} = NPC.update_item(npc_item.id, %{"drop_rate" => 15})

    assert npc_item.drop_rate == 15

    npc = NPC.get(npc.id)
    [%{drop_rate: 15}] = npc.npc_items

    state = Game.NPC._get_state(npc_spawner.id)
    [%{drop_rate: 15}] = state.npc.npc_items
  end

  test "deleting an item npc an NPC" do
    npc = create_npc(%{name: "Fighter"})
    armor = create_item(%{name: "Armor"})

    {:ok, zone} = Zone.create(zone_attributes(%{name: "The Forest"}))
    {:ok, room} = Room.create(zone, room_attributes(%{name: "Forest Path"}))
    {:ok, npc_spawner} = NPC.add_spawner(npc, %{zone_id: zone.id, room_id: room.id, spawn_interval: 15})

    {:ok, npc_item} = NPC.add_item(npc, %{"item_id" => armor.id, "drop_rate" => 10})
    {:ok, _npc_item} = NPC.delete_item(npc_item.id)

    npc = NPC.get(npc.id)
    assert npc.npc_items == []

    state = Game.NPC._get_state(npc_spawner.id)
    assert state.npc.npc_items == []
  end

  describe "events" do
    setup do
      npc = create_npc(%{
        events: [
          %{
            id: UUID.uuid4(),
            type: "room/entered",
            action: %{type: "say", message: "Hi"}
          }
        ]
      })

      %{npc: npc, event: List.first(npc.events)}
    end

    test "force save of loaded events", %{npc: npc} do
      {:ok, npc} = NPC.force_save_events(npc)

      assert length(npc.events) == 1
    end

    test "add an event", %{npc: npc} do
      event = %{
        type: "room/entered",
        action: %{type: "say", message: "Hi"}
      }

      {:ok, npc} = NPC.add_event(npc, Poison.encode!(event))

      assert length(npc.events) == 2
    end

    test "add an event - invalid", %{npc: npc} do
      event = %{type: "room/entered", action: %{type: "say"}}

      {:error, :invalid, changeset} = NPC.add_event(npc, Poison.encode!(event))
      assert changeset.errors
    end

    test "edit an event", %{npc: npc, event: event} do
      event = %{event | action: %{type: "say", message: "Hello"}}
      {:ok, npc} = NPC.edit_event(npc, event.id, Poison.encode!(event))

      event = List.first(npc.events)
      assert event.action.message == "Hello"
    end

    test "delete an event", %{npc: npc, event: event} do
      {:ok, npc} = NPC.delete_event(npc, event.id)
      assert Enum.empty?(npc.events)
    end
  end

  describe "trainable skills" do
    setup do
      npc = create_npc(%{is_trainer: true})
      skill = create_skill()
      %{npc: npc, skill: skill}
    end

    test "adding a new skill", %{npc: npc, skill: skill} do
      {:ok, npc} = NPC.add_trainable_skill(npc, skill.id)

      assert npc.trainable_skills == [skill.id]
    end

    test "removing a new skill", %{npc: npc, skill: skill} do
      {:ok, npc} = NPC.add_trainable_skill(npc, skill.id)
      {:ok, npc} = NPC.remove_trainable_skill(npc, skill.id)

      assert npc.trainable_skills == []
    end
  end
end
