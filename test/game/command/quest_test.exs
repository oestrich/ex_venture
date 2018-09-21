defmodule Game.Command.QuestTest do
  use Data.ModelCase
  doctest Game.Command.Quest

  alias Game.Character
  alias Game.Command.Quest

  @socket Test.Networking.Socket
  @room Test.Game.Room
  @npc Test.Game.NPC

  setup do
    @socket.clear_messages
    user = create_user(%{name: "user", password: "password"})
    user = %{user | class: %{name: "Fighter"}}

    %{state: %{socket: :socket, user: user, save: %{user.save | items: []}}}
  end

  describe "listing out quests" do
    setup do
      npc = create_npc(%{is_quest_giver: true})
      quest = create_quest(npc, %{name: "Into the Dungeon"})

      %{npc: Character.Simple.from_npc(npc), quest: quest}
    end

    test "with no active quests", %{state: state} do
      :ok = Quest.run({:list, :active}, state)

      [{_, quests}] = @socket.get_echos()
      assert Regex.match?(~r/no active quests/, quests)
    end

    test "a quest is in progress", %{state: state, quest: quest} do
      create_quest_progress(state.user, quest)

      :ok = Quest.run({:list, :active}, state)

      [{_, quests}] = @socket.get_echos()
      assert Regex.match?(~r/1 active quest/, quests)
      assert Regex.match?(~r/Into the Dungeon/, quests)
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
      create_quest_progress(state.user, quest)

      :ok = Quest.run({:show, to_string(quest.id)}, state)

      [{_, quest}] = @socket.get_echos()
      assert Regex.match?(~r/Into the Dungeon/, quest)
      assert Regex.match?(~r/Goblin/, quest)
      assert Regex.match?(~r/Potion/, quest)
    end

    test "viewing your tracked quest", %{state: state, quest: quest} do
      create_quest_progress(state.user, quest)
      Game.Quest.track_quest(state.user, quest.id)

      :ok = Quest.run({:show, :tracked}, state)

      [{_, quest}] = @socket.get_echos()
      assert Regex.match?(~r/Into the Dungeon/, quest)
      assert Regex.match?(~r/Goblin/, quest)
      assert Regex.match?(~r/Potion/, quest)
    end

    test "viewing your tracked quest - no tracked quest", %{state: state, quest: quest} do
      create_quest_progress(state.user, quest)

      :ok = Quest.run({:show, :tracked}, state)

      [{_, quest}] = @socket.get_echos()
      assert Regex.match?(~r/do not/i, quest)
    end

    test "viewing a quest that you do not have", %{state: state, quest: quest} do
      :ok = Quest.run({:show, to_string(quest.id)}, state)

      [{_, quest}] = @socket.get_echos()
      assert Regex.match?(~r/You have not started this quest/, quest)
    end

    test "sending not an integer as the id", %{state: state} do
      :ok = Quest.run({:show, "anything"}, state)

      [{_, quest}] = @socket.get_echos()
      assert Regex.match?(~r/could not parse/i, quest)
    end
  end

  describe "complete a quest" do
    setup %{state: state} do
      guard = create_npc(%{name: "Guard", is_quest_giver: true})
      guard = Map.put(guard, :original_id, guard.id)
      quest = create_quest(guard, %{name: "Into the Dungeon", experience: 200, currency: 25})

      room = Map.merge(@room._room(), %{
        npcs: [Character.Simple.from_npc(guard)],
      })
      @room.set_room(room)
      @npc.clear_notifies()

      state = state |> Map.put(:save, %{state.save | room_id: 1, level: 1, experience_points: 20, currency: 15})

      %{quest: quest, state: state}
    end

    test "completing a quest", %{state: state, quest: quest} do
      goblin = create_npc(%{name: "Goblin"})
      npc_step = create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: goblin.id})
      create_quest_progress(state.user, quest, %{progress: %{npc_step.id => 3}})

      {:update, state} = Quest.run({:complete, to_string(quest.id)}, state)

      [{_, quest}, {_, _experience}] = @socket.get_echos()
      assert Regex.match?(~r/quest complete/i, quest)
      assert Regex.match?(~r/25 gold/i, quest)
      assert state.save.currency == 40
      assert state.save.experience_points == 220
    end

    test "completing a quest - notifies the npc", %{state: state, quest: quest} do
      goblin = create_npc(%{name: "Goblin"})
      npc_step = create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: goblin.id})
      create_quest_progress(state.user, quest, %{progress: %{npc_step.id => 3}})

      {:update, _state} = Quest.run({:complete, to_string(quest.id)}, state)

      giver_id = quest.giver_id
      quest_id = quest.id
      assert [{^giver_id, {"quest/completed", _, %{id: ^quest_id}}}] = @npc.get_notifies()
    end

    test "giver is not in your room", %{state: state, quest: quest} do
      goblin = create_npc(%{name: "Goblin"})
      npc_step = create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: goblin.id})
      create_quest_progress(state.user, quest, %{progress: %{npc_step.id => 3}})
      @room.set_room(Map.merge(@room._room(), %{npcs: []}))

      :ok = Quest.run({:complete, to_string(quest.id)}, state)

      [{_, quest}] = @socket.get_echos()
      assert Regex.match?(~r/cannot be found/, quest)
    end

    test "have not completed the steps", %{state: state, quest: quest} do
      goblin = create_npc(%{name: "Goblin"})
      create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: goblin.id})
      create_quest_progress(state.user, quest, %{progress: %{}})

      :ok = Quest.run({:complete, to_string(quest.id)}, state)

      [{_, quest}] = @socket.get_echos()
      assert Regex.match?(~r/You have not completed the requirements/, quest)
    end

    test "quest is already complete", %{state: state, quest: quest} do
      create_quest_progress(state.user, quest, %{status: "complete"})

      :ok = Quest.run({:complete, to_string(quest.id)}, state)

      [{_, quest}] = @socket.get_echos()
      assert Regex.match?(~r/already complete/, quest)
    end

    test "completing a quest that you do not have", %{state: state, quest: quest} do
      :ok = Quest.run({:complete, to_string(quest.id)}, state)

      [{_, quest}] = @socket.get_echos()
      assert Regex.match?(~r/You have not started this quest/, quest)
    end

    test "completing a quest with a shortcut command", %{state: state, quest: quest} do
      create_quest_progress(state.user, quest)

      {:update, _state} = Quest.run({:complete, :any}, state)

      [{_, quest}, {_, _experience}] = @socket.get_echos()
      assert Regex.match?(~r/quest complete/i, quest)
      assert Regex.match?(~r/25 gold/i, quest)
    end
  end

  describe "track a quest" do
    setup do
      guard = create_npc(%{name: "Guard", is_quest_giver: true})
      quest = create_quest(guard, %{name: "Into the Dungeon"})

      %{quest: quest}
    end

    test "tracking a quest", %{state: state, quest: quest} do
      create_quest_progress(state.user, quest)

      :ok = Quest.run({:track, to_string(quest.id)}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r/tracking/i, echo)
    end

    test "tracking a quest - not part of your quest", %{state: state, quest: quest} do
      :ok = Quest.run({:track, to_string(quest.id)}, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r/not started/i, echo)
    end
  end

  describe "completing a quest with a shortcut" do
    setup %{state: state} do
      guard = create_npc(%{name: "Guard", is_quest_giver: true})
      guard = Map.put(guard, :original_id, guard.id)
      quest = create_quest(guard, %{name: "Into the Dungeon", experience: 200, currency: 25})

      room = Map.merge(@room._room(), %{
        npcs: [Character.Simple.from_npc(guard)],
      })
      @room.set_room(room)
      @npc.clear_notifies()

      state = state |> Map.put(:save, %{state.save | room_id: 1, level: 1, experience_points: 20, currency: 15})

      %{quest: quest, guard: guard, state: state}
    end

    test "finds any ready to finish quest with an NPC in the room", %{state: state, quest: quest, guard: guard} do
      second_quest = create_quest(guard)

      goblin = create_npc(%{name: "Goblin"})
      create_quest_step(second_quest, %{type: "npc/kill", count: 3, npc_id: goblin.id})

      create_quest_progress(state.user, quest)
      create_quest_progress(state.user, second_quest)

      {:update, _state} = Quest.run({:complete, :any}, state)

      [{_, quest}, {_, _experience}] = @socket.get_echos()
      assert Regex.match?(~r/quest complete/i, quest)
      assert Regex.match?(~r/25 gold/i, quest)
    end

    test "responds if you have no quests available to complete", %{state: state} do
      :ok = Quest.run({:complete, :any}, state)

      [{_, quest}] = @socket.get_echos()
      assert Regex.match?(~r/no quests/i, quest)
    end

    test "handles no npc in the room to hand in to", %{state: state, quest: quest} do
      create_quest_progress(state.user, quest)
      @room.set_room(Map.merge(@room._room(), %{npcs: []}))

      :ok = Quest.run({:complete, :any}, state)

      [{_, quest}] = @socket.get_echos()
      assert Regex.match?(~r/find the quest giver/i, quest)
    end
  end
end
