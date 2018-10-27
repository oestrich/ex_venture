defmodule Game.Format.QuestsTest do
  use ExUnit.Case

  alias Game.Format.Quests

  describe "quest details" do
    setup do
      guard = %{name: "Guard"}
      goblin = %{name: "Goblin"}
      potion = %{id: 5, name: "Potion"}

      step1 = %{id: 1, type: "npc/kill", count: 3, npc: goblin}
      step2 = %{id: 2, type: "item/collect", count: 4, item: potion, item_id: potion.id}
      step3 = %{id: 2, type: "item/have", count: 5, item: potion, item_id: potion.id}

      quest = %{
        id: 1,
        name: "Into the Dungeon",
        description: "Dungeon delving",
        giver: guard,
        quest_steps: [step1, step2, step3],
      }

      progress = %{status: "active", progress: %{step1.id => 2}, quest: quest}
      save = %{items: [%{id: potion.id}, %{id: potion.id}], wearing: %{}, wielding: %{}}

      %{quest: quest, progress: progress, save: save}
    end

    test "includes quest name", %{progress: progress, save: save} do
      assert Regex.match?(~r/Into the Dungeon/, Quests.quest_detail(progress, save))
    end

    test "includes quest description", %{progress: progress, save: save} do
      assert Regex.match?(~r/Dungeon delving/, Quests.quest_detail(progress, save))
    end

    test "includes quest status", %{progress: progress, save: save} do
      assert Regex.match?(~r/active/, Quests.quest_detail(progress, save))
    end

    test "includes item collect step", %{progress: progress, save: save} do
      assert Regex.match?(~r(Collect {item}Potion{/item} - 2/4), Quests.quest_detail(progress, save))
    end

    test "includes item have step", %{progress: progress, save: save} do
      assert Regex.match?(~r(Have {item}Potion{/item} - 2/5), Quests.quest_detail(progress, save))
    end

    test "includes npc step", %{progress: progress, save: save} do
      assert Regex.match?(~r(Kill {npc}Goblin{/npc} - 2/3), Quests.quest_detail(progress, save))
    end
  end
end
