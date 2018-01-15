defmodule Game.Command.QuestTest do
  use Data.ModelCase
  doctest Game.Command.Quest

  alias Game.Command.Quest

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages
    user = create_user(%{name: "user", password: "password"})
    %{session: :session, state: %{socket: :socket, user: user}}
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
end
