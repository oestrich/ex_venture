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

  describe "track progress - npc kill" do
    setup do
      user = create_user()
      goblin = create_npc(%{name: "Goblin"})
      %{user: user, goblin: goblin}
    end

    test "no current quest that matches", %{user: user, goblin: goblin} do
      assert :ok = Quest.track_progress(user, {:npc, goblin})
    end

    test "updates any quest progresses that match the user and the npc", %{user: user, goblin: goblin} do
      guard = create_npc(%{name: "Guard"})
      quest = create_quest(guard, %{name: "Into the Dungeon", experience: 200})
      npc_step = create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: goblin.id})
      quest_progress = create_quest_progress(user, quest)

      assert :ok = Quest.track_progress(user, {:npc, goblin})

      quest_progress = Data.Repo.get(QuestProgress, quest_progress.id)
      assert quest_progress.progress == %{npc_step.id => 1}
    end

    test "ignores steps if they do not match the npc being passed in", %{user: user, goblin: goblin} do
      guard = create_npc(%{name: "Guard"})
      quest = create_quest(guard, %{name: "Into the Dungeon", experience: 200})
      create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: goblin.id})
      quest_progress = create_quest_progress(user, quest)

      assert :ok = Quest.track_progress(user, {:npc, guard})

      quest_progress = Data.Repo.get(QuestProgress, quest_progress.id)
      assert quest_progress.progress == %{}
    end
  end

  describe "next available quest" do
    test "find the next quest available from an NPC" do
      guard = create_npc(%{name: "Guard"})

      quest1 = create_quest(guard, %{name: "Root 1"})
      quest2 = create_quest(guard, %{name: "Root 2"})
      quest3 = create_quest(guard, %{name: "Child Root 1"})
      create_quest_relation(quest3, quest1)
      quest4 = create_quest(guard, %{name: "Child Root 2"})
      create_quest_relation(quest4, quest2)
      quest5 = create_quest(guard, %{name: "Child Child Root 1"})
      create_quest_relation(quest5, quest3)

      user = create_user()

      {:ok, next_quest} = Quest.next_available_quest_from(guard, user)
      assert next_quest.id == quest1.id

      create_quest_progress(user, quest1, %{status: "complete"})
      {:ok, next_quest} = Quest.next_available_quest_from(guard, user)
      assert next_quest.id == quest2.id

      create_quest_progress(user, quest2, %{status: "complete"})
      {:ok, next_quest} = Quest.next_available_quest_from(guard, user)
      assert next_quest.id == quest3.id

      create_quest_progress(user, quest3, %{status: "complete"})
      {:ok, next_quest} = Quest.next_available_quest_from(guard, user)
      assert next_quest.id == quest4.id

      create_quest_progress(user, quest4, %{status: "complete"})
      {:ok, next_quest} = Quest.next_available_quest_from(guard, user)
      assert next_quest.id == quest5.id

      create_quest_progress(user, quest5, %{status: "complete"})
      assert {:error, :no_quests} = Quest.next_available_quest_from(guard, user)
    end

    test "stops if it hits an in progress quest" do
      guard = create_npc(%{name: "Guard"})

      quest1 = create_quest(guard, %{name: "Root 1"})
      quest2 = create_quest(guard, %{name: "Root 2"})
      quest3 = create_quest(guard, %{name: "Child Root 1"})
      create_quest_relation(quest3, quest1)

      user = create_user()

      {:ok, next_quest} = Quest.next_available_quest_from(guard, user)
      assert next_quest.id == quest1.id

      create_quest_progress(user, quest1, %{status: "complete"})
      {:ok, next_quest} = Quest.next_available_quest_from(guard, user)
      assert next_quest.id == quest2.id

      create_quest_progress(user, quest2, %{status: "active"})
      assert {:error, :in_progress} = Quest.next_available_quest_from(guard, user)
    end
  end
end
