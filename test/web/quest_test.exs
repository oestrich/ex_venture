defmodule Web.QuestTest do
  use Data.ModelCase

  alias Web.Quest

  test "creating a quest" do
    npc = create_npc()

    params = %{
      "name" => "Finding a Guard",
      "description" => "You must go find and talk to a guard",
      "giver_id" => npc.id,
      "level" => 1,
    }

    {:ok, quest} = Quest.create(params)

    assert quest.name == "Finding a Guard"
  end

  test "updating a quest" do
    npc = create_npc()
    quest = create_quest(npc, %{name: "Finding a Guard"})

    {:ok, quest} = Quest.update(quest.id, %{name: "Kill a Guard"})

    assert quest.name == "Kill a Guard"
  end

  describe "quest steps" do
    setup do
      npc = create_npc()
      quest = create_quest(npc, %{name: "Finding a Guard"})
      %{quest: quest, npc: npc}
    end

    test "add a quest step", %{quest: quest, npc: npc} do
      {:ok, step} = Quest.create_step(quest, %{type: "npc/kill", count: 3, npc_id: npc.id})

      assert step.type == "npc/kill"
      assert step.npc_id == npc.id
    end

    test "update a quest step", %{quest: quest, npc: npc} do
      step = create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: npc.id})

      {:ok, step} = Quest.update_step(step.id, %{count: 4})

      assert step.count == 4
    end
  end

  describe "quest relations" do
    setup do
      %{npc: create_npc()}
    end

    test "add a quest relation", %{npc: npc} do
      quest1 = create_quest(npc, %{name: "Finding a Guard 1"})
      quest2 = create_quest(npc, %{name: "Finding a Guard 2"})

      {:ok, relation} = Quest.create_relation(quest1, "parent", %{child_id: quest2.id})

      assert relation.parent_id == quest1.id
      assert relation.child_id == quest2.id
    end

    test "delete a quest relation", %{npc: npc} do
      quest1 = create_quest(npc, %{name: "Finding a Guard 1"})
      quest2 = create_quest(npc, %{name: "Finding a Guard 2"})

      {:ok, relation} = Quest.create_relation(quest1, "parent", %{child_id: quest2.id})
      {:ok, _relation} = Quest.delete_relation(relation.id)
    end
  end
end
