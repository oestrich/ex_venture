defmodule Game.NPCTest do
  use Data.ModelCase

  @room Test.Game.Room

  alias Game.NPC
  alias Game.NPC.State
  alias Game.Session.Registry

  setup do
    @room.clear_notifies()
    @room.clear_says()
    @room.clear_leaves()
  end

  test "applying effects" do
    effect = %{kind: "damage", type: :slashing, amount: 10}

    state = %State{npc: %{id: 1, name: "NPC", stats: %{health: 25}}}
    {:noreply, state} = NPC.handle_cast({:apply_effects, [effect], {:user, %{id: 2}}, "description"}, state)
    assert state.npc.stats.health == 15
  end

  test "applying continuous effects - damage over time" do
    effect = %{kind: "damage/over-time", type: :slashing, every: 10, count: 3, amount: 10}

    state = %State{npc: %{id: 1, name: "NPC", stats: %{health: 25}}, continuous_effects: []}
    {:noreply, state} = NPC.handle_cast({:apply_effects, [effect], {:user, %{id: 2}}, "description"}, state)
    [effect] = state.continuous_effects
    assert effect.kind == "damage/over-time"
    assert effect.id

    effect_id = effect.id
    assert_receive {:continuous_effect, ^effect_id}
  end

  test "applying effects - died" do
    effect = %{kind: "damage", type: :slashing, amount: 10}

    npc = %{currency: 0, npc_items: [], id: 1, name: "NPC", stats: %{health: 10}}
    npc_spawner = %{spawn_interval: 0}
    state = %State{room_id: 1, npc: npc, npc_spawner: npc_spawner}
    {:noreply, state} = NPC.handle_cast({:apply_effects, [effect], {:user, %{id: 2}}, "description"}, state)
    assert state.npc.stats.health == 0

    assert [{1, {:npc, _}, :death}] = @room.get_leaves()
    assert [{1, {"character/died", _, _, _}}] = @room.get_notifies()

    Registry.unregister()
  end
end
