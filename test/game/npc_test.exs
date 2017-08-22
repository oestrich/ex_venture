defmodule Game.NPCTest do
  use Data.ModelCase

  @room Test.Game.Room

  alias Game.NPC

  test "being targeted makes the npc say something" do
    targeter = {:user, %{id: 10, name: "Player"}}

    {:noreply, state} = NPC.handle_cast({:targeted, targeter}, %{npc: %{name: "NPC", room_id: 1}, is_targeting: MapSet.new})

    [{_, message}] = @room.get_says()
    assert message.message == "Why are you targeting me, Player?"

    assert state.is_targeting |> MapSet.size() == 1
    assert state.is_targeting |> MapSet.member?({:user, 10})
  end

  test "a player removing a target stops tracking them" do
    targeter = {:user, %{id: 10, name: "Player"}}
    is_targeting = MapSet.new() |> MapSet.put({:user, 10})

    {:noreply, state} = NPC.handle_cast({:remove_target, targeter}, %{is_targeting: is_targeting})

    assert state.is_targeting |> MapSet.size() == 0
    refute state.is_targeting |> MapSet.member?({:user, 10})
  end

  test "applying effects" do
    effect = %{kind: "damage", type: :slashing, amount: 10}

    {:noreply, state} = NPC.handle_cast({:apply_effects, [effect], {:user, 1}, "description"}, %{npc: %{name: "NPC", stats: %{health: 25}, room_id: 1}})
    assert state.npc.stats.health == 15
  end

  test "applying effects - died" do
    effect = %{kind: "damage", type: :slashing, amount: 10}

    {:noreply, state} = NPC.handle_cast({:apply_effects, [effect], {:user, 1}, "description"}, %{npc: %{name: "NPC", stats: %{health: 10}, room_id: 1}})
    assert state.npc.stats.health == 0

    [{_, message}] = @room.get_says()
    assert message.message == "I died!"
  end
end
