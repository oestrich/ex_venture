defmodule Game.NPCTest do
  use Data.ModelCase

  import Test.DamageTypesHelper

  @room Test.Game.Room

  alias Game.NPC
  alias Game.NPC.State
  alias Game.Session.Registry

  setup do
    @room.clear_notifies()
    @room.clear_says()
    @room.clear_leaves()

    start_and_clear_damage_types()

    insert_damage_type(%{
      key: "slashing",
      stat_modifier: :strength,
      boost_ratio: 20,
      reverse_stat: :agility,
      reverse_boost: 20,
    })

    :ok
  end

  test "applying effects" do
    effect = %{kind: "damage", type: "slashing", amount: 15}
    state = %State{npc: %{id: 1, name: "NPC", stats: %{health_points: 25, agility: 10}}}

    {:noreply, state} = NPC.handle_cast({:apply_effects, [effect], {:player, %{id: 2, name: "Player"}}, "description"}, state)
    assert state.npc.stats.health_points == 15
  end

  test "applying continuous effects - damage over time" do
    effect = %{kind: "damage/over-time", type: "slashing", every: 10, count: 3, amount: 15}
    from = {:player, %{id: 2, name: "Player"}}

    state = %State{
      npc: %{id: 1, name: "NPC", stats: %{health_points: 25, agility: 10}},
      continuous_effects: [],
    }

    {:noreply, state} = NPC.handle_cast({:apply_effects, [effect], from, "description"}, state)
    [{^from, effect}] = state.continuous_effects
    assert effect.kind == "damage/over-time"
    assert effect.id

    effect_id = effect.id
    assert_receive {:continuous_effect, ^effect_id}
  end

  test "applying effects - died" do
    effect = %{kind: "damage", type: "slashing", amount: 15}

    npc = %{currency: 0, npc_items: [], id: 1, name: "NPC", stats: %{health_points: 10, agility: 10}}
    npc_spawner = %{spawn_interval: 0}
    state = %State{room_id: 1, npc: npc, npc_spawner: npc_spawner}

    {:noreply, state} = NPC.handle_cast({:apply_effects, [effect], {:player, %{id: 2, name: "Player"}}, "description"}, state)
    assert state.npc.stats.health_points == 0

    assert [{1, {:npc, _}, :death}] = @room.get_leaves()
    assert [{1, {"character/died", _, _, _}}] = @room.get_notifies()

    Registry.unregister()
  end
end
