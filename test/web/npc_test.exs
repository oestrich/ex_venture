defmodule Web.NPCTest do
  use Data.ModelCase

  alias Web.NPC

  test "create a new npc" do
    params = %{
      "name" => "Bandit",
      "level" => "1",
      "experience_points" => "124",
      "currency" => "10",
      "tags" => "enemy, dungeon",
      "script" => [
        %{"key" => "start", "message" => "Hi"},
      ] |> Poison.encode!(),
      "stats" => %{
        health_points: 25,
        max_health_points: 25,
        skill_points: 10,
        max_skill_points: 10,
        endurance_points: 10,
        max_endurance_points: 10,
        strength: 10,
        agility: 10,
        intelligence: 10,
        awareness: 10,
        vitality: 13,
        willpower: 10,
      } |> Poison.encode!(),
    }

    {:ok, npc} = NPC.create(params)

    assert npc.name == "Bandit"
    assert npc.tags == ["enemy", "dungeon"]
    assert npc.script |> length() == 1
  end

  test "updating a npc" do
    npc = create_npc(%{name: "Fighter"})
    zone = create_zone()
    room = create_room(zone)
    npc_spawner = create_npc_spawner(npc, %{zone_id: zone.id, room_id: room.id, spawn_interval: 15})

    :yes = :global.register_name({Game.NPC, npc_spawner.id}, self())

    {:ok, npc} = NPC.update(npc.id, %{name: "Barbarian"})

    assert npc.name == "Barbarian"
    assert_receive {:"$gen_cast", {:update, _}}
  end

  test "adding a new spawner" do
    zone = create_zone(%{name: "The Forest"})
    room = create_room(zone, %{name: "Forest Path"})

    npc = create_npc(%{name: "Fighter"})

    :yes = :global.register_name({Game.Zone, zone.id}, self())

    {:ok, npc_spawner} = NPC.add_spawner(npc, %{zone_id: zone.id, room_id: room.id, spawn_interval: 15})

    assert npc_spawner.zone_id == zone.id

    assert_receive {:"$gen_cast", {:spawn_npc, _}}
  end

  test "updating a spawner" do
    npc = create_npc(%{name: "Fighter"})

    zone = create_zone()
    room = create_room(zone)
    npc_spawner = create_npc_spawner(npc, %{zone_id: zone.id, room_id: room.id, spawn_interval: 15})

    :yes = :global.register_name({Game.NPC, npc_spawner.id}, self())

    {:ok, npc_spawner} = NPC.update_spawner(npc_spawner.id, %{spawn_interval: 30})

    assert npc_spawner.spawn_interval == 30
    assert_receive {:"$gen_cast", {:update, _}}
  end

  test "deleting a spawner" do
    npc = create_npc(%{name: "Fighter"})

    zone = create_zone()
    room = create_room(zone)
    npc_spawner = create_npc_spawner(npc, %{zone_id: zone.id, room_id: room.id, spawn_interval: 15})

    :yes = :global.register_name({Game.NPC, npc_spawner.id}, self())

    assert {:ok, _npc_spanwer} = NPC.delete_spawner(npc_spawner.id)
    assert_receive {:"$gen_cast", :terminate}
  end

  test "adding an item to an NPC" do
    npc = create_npc()
    armor = create_item()

    zone = create_zone()
    room = create_room(zone)
    npc_spawner = create_npc_spawner(npc, %{zone_id: zone.id, room_id: room.id, spawn_interval: 15})

    :yes = :global.register_name({Game.NPC, npc_spawner.id}, self())

    {:ok, npc_item} = NPC.add_item(npc, %{"item_id" => armor.id, "drop_rate" => 10})

    assert npc_item.drop_rate == 10
    assert_receive {:"$gen_cast", {:update, _}}
  end

  test "updating an item on an npc" do
    npc = create_npc()
    armor = create_item()

    zone = create_zone()
    room = create_room(zone)
    npc_spawner = create_npc_spawner(npc, %{zone_id: zone.id, room_id: room.id, spawn_interval: 15})

    :yes = :global.register_name({Game.NPC, npc_spawner.id}, self())

    {:ok, npc_item} = NPC.add_item(npc, %{"item_id" => armor.id, "drop_rate" => 10})
    {:ok, npc_item} = NPC.update_item(npc_item.id, %{"drop_rate" => 15})

    assert npc_item.drop_rate == 15
    assert_receive {:"$gen_cast", {:update, _}}
    assert_receive {:"$gen_cast", {:update, _}}
  end

  test "deleting an item npc an NPC" do
    npc = create_npc(%{name: "Fighter"})
    armor = create_item(%{name: "Armor"})

    zone = create_zone()
    room = create_room(zone)
    npc_spawner = create_npc_spawner(npc, %{zone_id: zone.id, room_id: room.id, spawn_interval: 15})

    :yes = :global.register_name({Game.NPC, npc_spawner.id}, self())

    {:ok, npc_item} = NPC.add_item(npc, %{"item_id" => armor.id, "drop_rate" => 10})
    {:ok, _npc_item} = NPC.delete_item(npc_item.id)

    assert_receive {:"$gen_cast", {:update, _}}
    assert_receive {:"$gen_cast", {:update, _}}
  end

  describe "events" do
    setup do
      npc = create_npc(%{
        events: [
          %{
            "id" => UUID.uuid4(),
            "type" => "room/entered",
            "actions" => [
              %{"type" => "commands/say", "options" => %{"message" => "Hi"}}
            ]
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
        "type" => "room/entered",
        "actions" => [
          %{"type" => "commands/say", "options" => %{"message" => "Hi"}}
        ]
      }

      {:ok, npc} = NPC.add_event(npc, Poison.encode!(event))

      assert length(npc.events) == 2
    end

    test "edit an event", %{npc: npc, event: event} do
      event = %{event | "actions" => [%{type: "commands/say", options: %{message: "Hello"}}]}
      {:ok, npc} = NPC.edit_event(npc, event["id"], Poison.encode!(event))

      event = List.first(npc.events)
      action = List.first(event["actions"])
      assert action["options"]["message"] == "Hello"
    end

    test "delete an event", %{npc: npc, event: event} do
      {:ok, npc} = NPC.delete_event(npc, event["id"])
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
