defmodule Game.NPCTest do
  use Data.ModelCase

  @room Test.Game.Room

  alias Game.NPC

  test "being targeted makes the npc say something" do
    {:noreply, _state} = NPC.handle_cast({:targeted, %{name: "Player"}}, %{npc: %{name: "NPC", room_id: 1}})

    [{_, message}] = @room.get_says()
    assert message.message == "Why are you targeting me, Player?"
  end

  test "applying effects" do
    effect = %{kind: "damage", type: :slashing, amount: 10}

    {:noreply, state} = NPC.handle_cast({:apply_effects, [effect], {:user, 1}}, %{npc: %{name: "NPC", stats: %{health: 25}, room_id: 1}})
    assert state.npc.stats.health == 15
  end

  test "applying effects - died" do
    effect = %{kind: "damage", type: :slashing, amount: 10}

    {:noreply, state} = NPC.handle_cast({:apply_effects, [effect], {:user, 1}}, %{npc: %{name: "NPC", stats: %{health: 10}, room_id: 1}})
    assert state.npc.stats.health == 0

    [{_, message}] = @room.get_says()
    assert message.message == "I died!"
  end
end
