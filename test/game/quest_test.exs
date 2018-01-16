defmodule Game.QuestTest do
  use Data.ModelCase

  alias Data.QuestProgress
  alias Data.QuestStep
  alias Game.Quest

  describe "current step progress" do
    test "item/collect - no progress on a step yet" do
      step = %QuestStep{type: "item/collect", item_id: 1}
      progress = %QuestProgress{progress: %{}}
      save = %{items: []}

      assert Quest.current_step_progress(step, progress, save) == 0
    end

    test "item/collect - progress started" do
      step = %QuestStep{id: 1, type: "item/collect", item_id: 1}
      progress = %QuestProgress{progress: %{}}
      save = %{items: [item_instance(1)]}

      assert Quest.current_step_progress(step, progress, save) == 1
    end

    test "npc/kill - no progress on a step yet" do
      step = %QuestStep{type: "npc/kill"}
      progress = %QuestProgress{progress: %{}}
      save = %{}

      assert Quest.current_step_progress(step, progress, save) == 0
    end

    test "npc/kill - progress started" do
      step = %QuestStep{id: 1, type: "npc/kill"}
      progress = %QuestProgress{progress: %{step.id => 3}}
      save = %{}

      assert Quest.current_step_progress(step, progress, save) == 3
    end
  end

  describe "determine if a user has all progress required for a quest" do
    test "quest complete when all step requirements are met - npc" do
      step = %QuestStep{id: 1, type: "npc/kill", count: 2}
      quest = %Data.Quest{quest_steps: [step]}
      progress = %QuestProgress{progress: %{step.id => 2}, quest: quest}
      save = %{}

      assert Quest.requirements_complete?(progress, save)
    end

    test "quest complete when all step requirements are met - item" do
      step = %QuestStep{id: 1, type: "item/collect", count: 2, item_id: 2}
      quest = %Data.Quest{quest_steps: [step]}
      progress = %QuestProgress{progress: %{}, quest: quest}
      save = %{items: [item_instance(2), item_instance(2)]}

      assert Quest.requirements_complete?(progress, save)
    end
  end

  describe "complete a quest" do
    test "marks the quest progress as complete" do
      guard = create_npc(%{name: "Guard"})
      goblin = create_npc(%{name: "Goblin"})
      quest = create_quest(guard, %{name: "Into the Dungeon", experience: 200})
      potion = create_item(%{name: "Potion"})

      npc_step = create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: goblin.id})
      create_quest_step(quest, %{type: "item/collect", count: 1, item_id: potion.id})

      user = create_user()
      items = [item_instance(potion.id), item_instance(potion.id), item_instance(potion), item_instance(3)]
      user = %{user | save: %{user.save | items: items, experience_points: 20}}
      create_quest_progress(user, quest, %{progress: %{npc_step.id => 3}})
      progress = Quest.progress_for(user, quest.id) # get preloads

      {:ok, save} = Quest.complete(progress, user.save)

      assert Data.Repo.get(QuestProgress, progress.id).status == "complete"
      assert save.items |> length() == 3
    end
  end
end
