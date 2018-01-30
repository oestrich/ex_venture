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

  test "being targeted tracks the target" do
    targeter = {:user, %{id: 10, name: "Player"}}

    {:noreply, state} =
      NPC.handle_cast({:targeted, targeter}, %{npc: %{name: "NPC"}, is_targeting: MapSet.new()})

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

  describe "a player died" do
    test "clears their target if that player was their target" do
      target = {:user, %{id: 10, name: "Player"}}
      {:noreply, state} = NPC.handle_cast({:died, target}, %{target: {:user, 10}, npc: %{id: 10}})

      assert is_nil(state.target)
    end
  end

  test "applying effects" do
    effect = %{kind: "damage", type: :slashing, amount: 10}

    state = %State{npc: %{id: 1, name: "NPC", stats: %{health: 25}}, is_targeting: MapSet.new()}
    {:noreply, state} = NPC.handle_cast({:apply_effects, [effect], {:user, %{id: 2}}, "description"}, state)
    assert state.npc.stats.health == 15
  end

  test "applying continuous effects - damage over time" do
    effect = %{kind: "damage/over-time", type: :slashing, every: 10, count: 3, amount: 10}

    state = %State{npc: %{id: 1, name: "NPC", stats: %{health: 25}}, is_targeting: MapSet.new(), continuous_effects: []}
    {:noreply, state} = NPC.handle_cast({:apply_effects, [effect], {:user, %{id: 2}}, "description"}, state)
    [effect] = state.continuous_effects
    assert effect.kind == "damage/over-time"
    assert effect.id

    effect_id = effect.id
    assert_receive {:continuous_effect, ^effect_id}
  end

  test "applying effects - died" do
    effect = %{kind: "damage", type: :slashing, amount: 10}

    is_targeting = MapSet.new |> MapSet.put({:user, 2})
    npc = %{currency: 0, npc_items: [], id: 1, name: "NPC", stats: %{health: 10}}
    npc_spawner = %{spawn_interval: 0}
    state = %State{room_id: 1, npc: npc, npc_spawner: npc_spawner, is_targeting: is_targeting}
    {:noreply, state} = NPC.handle_cast({:apply_effects, [effect], {:user, %{id: 2}}, "description"}, state)
    assert state.npc.stats.health == 0

    assert [{1, {:npc, _}, :death}] = @room.get_leaves()
    assert [{1, {"character/died", _, _, _}}] = @room.get_notifies()

    Registry.unregister()
  end
end
