defmodule Game.Command.QuestTest do
  use Data.ModelCase
  doctest Game.Command.Quest

  alias Game.Command.Quest

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    @socket.clear_messages
    user = create_user(%{name: "user", password: "password"})
    %{session: :session, state: %{socket: :socket, user: user, save: %{items: []}}}
  end

  describe "listing out quests" do
    setup do
      npc = create_npc()
      quest = create_quest(npc, %{name: "Into the Dungeon"})

      %{npc: npc, quest: quest}
    end

    test "with no active quests", %{session: session, state: state} do
      :ok = Quest.run({:list, :active}, session, state)

      [{_, quests}] = @socket.get_echos()
      assert Regex.match?(~r/no active quests/, quests)
    end

    test "a quest is in progress", %{session: session, state: state, quest: quest} do
      create_quest_progress(state.user, quest)

      :ok = Quest.run({:list, :active}, session, state)

      [{_, quests}] = @socket.get_echos()
      assert Regex.match?(~r/1 active quest/, quests)
      assert Regex.match?(~r/Into the Dungeon/, quests)
    end
  end

  describe "view a quest in more detail" do
    setup do
      guard = create_npc(%{name: "Guard"})
      goblin = create_npc(%{name: "Goblin"})
      quest = create_quest(guard, %{name: "Into the Dungeon"})
      potion = create_item(%{name: "Potion"})

      create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: goblin.id})
      create_quest_step(quest, %{type: "item/collect", count: 1, item_id: potion.id})

      %{quest: quest}
    end

    test "a quest is in progress", %{session: session, state: state, quest: quest} do
      create_quest_progress(state.user, quest)

      :ok = Quest.run({:show, to_string(quest.id)}, session, state)

      [{_, quest}] = @socket.get_echos()
      assert Regex.match?(~r/Into the Dungeon/, quest)
      assert Regex.match?(~r/Goblin/, quest)
      assert Regex.match?(~r/Potion/, quest)
    end

    test "viewing a quest that you do not have", %{session: session, state: state, quest: quest} do
      :ok = Quest.run({:show, to_string(quest.id)}, session, state)

      [{_, quest}] = @socket.get_echos()
      assert Regex.match?(~r/You have not started this quest/, quest)
    end
  end

  describe "complete a quest" do
    setup %{state: state} do
      guard = create_npc(%{name: "Guard"})
      quest = create_quest(guard, %{name: "Into the Dungeon", experience: 200})

      room = Map.merge(@room._room(), %{
        npcs: [Map.put(guard, :original_id, guard.id)],
      })
      @room.set_room(room)

      state = state |> Map.put(:save, %{room_id: 1, level: 1, experience_points: 20})

      %{quest: quest, state: state}
    end

    test "completing a quest", %{session: session, state: state, quest: quest} do
      goblin = create_npc(%{name: "Goblin"})
      npc_step = create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: goblin.id})
      create_quest_progress(state.user, quest, %{progress: %{npc_step.id => 3}})

      {:update, state} = Quest.run({:complete, to_string(quest.id)}, session, state)

      [{_, quest}, {_, _experience}] = @socket.get_echos()
      assert Regex.match?(~r/quest complete/i, quest)
      assert state.save.experience_points == 220
    end

    test "giver is not in your room", %{session: session, state: state, quest: quest} do
      goblin = create_npc(%{name: "Goblin"})
      npc_step = create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: goblin.id})
      create_quest_progress(state.user, quest, %{progress: %{npc_step.id => 3}})
      @room.set_room(Map.merge(@room._room(), %{npcs: []}))

      :ok = Quest.run({:complete, to_string(quest.id)}, session, state)

      [{_, quest}] = @socket.get_echos()
      assert Regex.match?(~r/cannot be found/, quest)
    end

    test "have not completed the steps", %{session: session, state: state, quest: quest} do
      goblin = create_npc(%{name: "Goblin"})
      create_quest_step(quest, %{type: "npc/kill", count: 3, npc_id: goblin.id})
      create_quest_progress(state.user, quest, %{progress: %{}})

      :ok = Quest.run({:complete, to_string(quest.id)}, session, state)

      [{_, quest}] = @socket.get_echos()
      assert Regex.match?(~r/You have not completed the requirements/, quest)
    end

    test "quest is already complete", %{session: session, state: state, quest: quest} do
      create_quest_progress(state.user, quest, %{status: "complete"})

      :ok = Quest.run({:complete, to_string(quest.id)}, session, state)

      [{_, quest}] = @socket.get_echos()
      assert Regex.match?(~r/already complete/, quest)
    end

    test "completing a quest that you do not have", %{session: session, state: state, quest: quest} do
      :ok = Quest.run({:complete, to_string(quest.id)}, session, state)

      [{_, quest}] = @socket.get_echos()
      assert Regex.match?(~r/You have not started this quest/, quest)
    end
  end
end
