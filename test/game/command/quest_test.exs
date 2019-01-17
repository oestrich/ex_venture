defmodule Game.Command.QuestTest do
  use ExVenture.CommandCase

  alias Game.Character
  alias Game.Command.Quest

  doctest Quest

  setup do
    user = create_user(%{name: "user", password: "password"})
    character = create_character(user)

    %{state: session_state(%{user: user, character: character, save: %{character.save | items: []}})}
  end

  describe "listing out quests" do
    setup do
      npc = create_npc(%{is_quest_giver: true})
      quest = create_quest(npc, %{name: "Into the Dungeon"})

      %{npc: Character.Simple.from_npc(npc), quest: quest}
    end

    test "with no active quests", %{state: state} do
      :ok = Quest.run({:list, :active}, state)

      assert_socket_echo "no active quests"
    end

    test "a quest is in progress", %{state: state, quest: quest} do
      create_quest_progress(state.character, quest)

      :ok = Quest.run({:list, :active}, state)

      assert_socket_echo ["1 active quest", "into the dungeon"]
    end
  end

  describe "view a quest in more detail" do
    setup do
      guard = create_npc(%{name: "Guard", is_quest_giver: true})
      goblin = create_npc(%{name: "Goblin"})
      quest = create_quest(guard, %{name: "Into the Dungeon"})
      potion = create_item(%{name: "Potion"})

      create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: goblin.id})
      create_quest_step(quest, %{type: "item/collect", count: 1, item_id: potion.id})

      %{quest: quest}
    end

    test "a quest is in progress", %{state: state, quest: quest} do
      create_quest_progress(state.character, quest)

      :ok = Quest.run({:show, to_string(quest.id)}, state)

      assert_socket_echo ["into the dungeon", "goblin", "potion"]
    end

    test "viewing your tracked quest", %{state: state, quest: quest} do
      create_quest_progress(state.character, quest)
      Game.Quest.track_quest(state.character, quest.id)

      :ok = Quest.run({:show, :tracked}, state)

      assert_socket_echo ["into the dungeon", "goblin", "potion"]
    end

    test "viewing your tracked quest - no tracked quest", %{state: state, quest: quest} do
      create_quest_progress(state.character, quest)

      :ok = Quest.run({:show, :tracked}, state)

      assert_socket_echo "do not"
    end

    test "viewing a quest that you do not have", %{state: state, quest: quest} do
      :ok = Quest.run({:show, to_string(quest.id)}, state)

      assert_socket_echo "have not started"
    end

    test "sending not an integer as the id", %{state: state} do
      :ok = Quest.run({:show, "anything"}, state)

      assert_socket_echo "could not parse"
    end
  end

  describe "complete a quest" do
    setup %{state: state} do
      guard = create_npc(%{name: "Guard", is_quest_giver: true})
      guard = Map.put(guard, :original_id, guard.id)
      quest = create_quest(guard, %{name: "Into the Dungeon", experience: 200, currency: 25})

      start_room(%{npcs: [Character.Simple.from_npc(guard)]})

      state = state |> Map.put(:save, %{state.save | room_id: 1, level: 1, experience_points: 20, currency: 15})

      %{quest: quest, state: state}
    end

    test "completing a quest", %{state: state, quest: quest} do
      goblin = create_npc(%{name: "Goblin"})
      npc_step = create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: goblin.id})
      create_quest_progress(state.character, quest, %{progress: %{npc_step.id => 3}})

      {:update, state} = Quest.run({:complete, to_string(quest.id)}, state)

      assert_socket_echo ["quest complete", "25 gold"]
      assert state.save.currency == 40
      assert state.save.experience_points == 220
    end

    test "completing a quest - notifies the npc", %{state: state, quest: quest} do
      goblin = create_npc(%{name: "Goblin"})
      npc_step = create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: goblin.id})
      create_quest_progress(state.character, quest, %{progress: %{npc_step.id => 3}})

      {:update, _state} = Quest.run({:complete, to_string(quest.id)}, state)

      assert_npc_notify {_, {"quest/completed", _, _}}
    end

    test "giver is not in your room", %{state: state, quest: quest} do
      goblin = create_npc(%{name: "Goblin"})
      npc_step = create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: goblin.id})
      create_quest_progress(state.character, quest, %{progress: %{npc_step.id => 3}})
      start_room(%{npcs: []})

      :ok = Quest.run({:complete, to_string(quest.id)}, state)

      assert_socket_echo "cannot be found"
    end

    test "have not completed the steps", %{state: state, quest: quest} do
      goblin = create_npc(%{name: "Goblin"})
      create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: goblin.id})
      create_quest_progress(state.character, quest, %{progress: %{}})

      :ok = Quest.run({:complete, to_string(quest.id)}, state)

      assert_socket_echo "have not completed"
    end

    test "quest is already complete", %{state: state, quest: quest} do
      create_quest_progress(state.character, quest, %{status: "complete"})

      :ok = Quest.run({:complete, to_string(quest.id)}, state)

      assert_socket_echo "already complete"
    end

    test "completing a quest that you do not have", %{state: state, quest: quest} do
      :ok = Quest.run({:complete, to_string(quest.id)}, state)

      assert_socket_echo "have not started"
    end

    test "completing a quest with a shortcut command", %{state: state, quest: quest} do
      create_quest_progress(state.character, quest)

      {:update, _state} = Quest.run({:complete, :any}, state)

      assert_socket_echo ["quest complete", "25 gold"]
    end
  end

  describe "track a quest" do
    setup do
      guard = create_npc(%{name: "Guard", is_quest_giver: true})
      quest = create_quest(guard, %{name: "Into the Dungeon"})

      %{quest: quest}
    end

    test "tracking a quest", %{state: state, quest: quest} do
      create_quest_progress(state.character, quest)

      :ok = Quest.run({:track, to_string(quest.id)}, state)

      assert_socket_echo "tracking"
    end

    test "tracking a quest - not part of your quest", %{state: state, quest: quest} do
      :ok = Quest.run({:track, to_string(quest.id)}, state)

      assert_socket_echo "not started"
    end
  end

  describe "completing a quest with a shortcut" do
    setup %{state: state} do
      guard = create_npc(%{name: "Guard", is_quest_giver: true})
      guard = Map.put(guard, :original_id, guard.id)
      quest = create_quest(guard, %{name: "Into the Dungeon", experience: 200, currency: 25})

      start_room(%{npcs: [Character.Simple.from_npc(guard)]})

      state = state |> Map.put(:save, %{state.save | room_id: 1, level: 1, experience_points: 20, currency: 15})

      %{quest: quest, guard: guard, state: state}
    end

    test "finds any ready to finish quest with an NPC in the room", %{state: state, quest: quest, guard: guard} do
      second_quest = create_quest(guard)

      goblin = create_npc(%{name: "Goblin"})
      create_quest_step(second_quest, %{type: "npc/kill", count: 3, npc_id: goblin.id})

      create_quest_progress(state.character, quest)
      create_quest_progress(state.character, second_quest)

      {:update, _state} = Quest.run({:complete, :any}, state)

      assert_socket_echo ["quest complete", "25 gold"]
    end

    test "responds if you have no quests available to complete", %{state: state} do
      :ok = Quest.run({:complete, :any}, state)

      assert_socket_echo "no quests"
    end

    test "handles no npc in the room to hand in to", %{state: state, quest: quest} do
      create_quest_progress(state.character, quest)
      start_room(%{npcs: []})

      :ok = Quest.run({:complete, :any}, state)

      assert_socket_echo "find the quest giver"
    end
  end
end
