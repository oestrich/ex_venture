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
end
