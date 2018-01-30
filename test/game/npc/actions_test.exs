defmodule Game.NPC.ActionsTest do
  use ExUnit.Case
  import Test.ItemsHelper
  doctest Game.NPC.Actions

  alias Game.NPC.Actions
  alias Game.NPC.State

  @room Test.Game.Room

  describe "tick - respawning the npc" do
    setup do
      @room.clear_enters()

      npc = %{id: 1, stats: %{health: 10, max_health: 15}}
      npc_spawner = %{room_id: 1, spawn_interval: 10}

      state = %State{npc: npc, npc_spawner: npc_spawner, room_id: 2}

      %{state: state, npc: npc}
    end

    test "respawns the npc", %{state: state, npc: npc} do
      state = %{state | npc: put_in(npc, [:stats, :health], 0)}

      state = Actions.handle_respawn(state)

      assert state.npc.stats.health == 15
      assert state.room_id == 1
      assert [{1, {:npc, _}, :respawn}] = @room.get_enters()
    end
  end

  describe "tick - cleaning up conversation state" do
    setup do
      npc = %{id: 1}

      time = Timex.now()

      state = %State{
        npc: npc,
        conversations: %{
          10 => %{key: "start", started_at: time |> Timex.shift(minutes: -10)},
          11 => %{key: "start", started_at: time |> Timex.shift(minutes: -1)},
        },
      }

      %{time: time, npc: npc, state: state}
    end

    test "cleans out conversations after 5 minutes", %{state: state, time: time} do
      state = Actions.clean_conversations(state, time)

      assert Map.keys(state.conversations) == [11]
    end
  end

  describe "dying" do
    setup do
      @room.clear_drop_currencies()
      @room.clear_drops()

      start_and_clear_items()
      insert_item(%{id: 1, name: "Sword", keywords: [], is_usable: false})
      insert_item(%{id: 2, name: "Shield", keywords: [], is_usable: false})

      npc_items = [
        %{item_id: 1, drop_rate: 50},
        %{item_id: 2, drop_rate: 50},
      ]

      npc = %{id: 1, name: "NPC", currency: 100, npc_items: npc_items}
      npc_spawner = %{id: 1, spawn_interval: 0}

      %{room_id: 1, npc: npc, npc_spawner: npc_spawner, is_targeting: [], target: nil}
    end

    test "triggers respawn", state do
      _state = Actions.died(state, {:npc, state.npc})

      assert_receive :respawn
    end

    test "drops currency in the room", state do
      _state = Actions.died(state, {:npc, state.npc})

      assert [{1, {:npc, _}, 51}] = @room.get_drop_currencies()
    end

    test "does not drop 0 currency", state do
      npc = %{state.npc | currency: 0}
      _state = Actions.died(%{state | npc: npc}, {:npc, state.npc})

      assert [] = @room.get_drop_currencies()
    end

    test "will drop an amount 50-100% of the total currency" do
      assert Actions.currency_amount_to_drop(100, Test.DropCurrency) == 80
    end

    test "drops items in the room", state do
      _state = Actions.died(state, {:npc, state.npc})

      assert [{1, {:npc, _}, %{id: 1}}, {1, {:npc, _}, %{id: 2}}] = @room.get_drops()
    end

    test "will drop an item if the chance is below the item's drop rate" do
      assert Actions.drop_item?(%{drop_rate: 50}, Test.ChanceSuccess)
    end

    test "will not drop an item if the chance is above the item's drop rate" do
      refute Actions.drop_item?(%{drop_rate: 50}, Test.ChanceFail)
    end
  end

  describe "continuous effects" do
    setup do
      effect = %{id: :id, kind: "damage/over-time", type: :slashing, every: 10, count: 3, amount: 10}
      npc = %{id: 1, name: "NPC", currency: 0, npc_items: [], stats: %{health: 25}}
      npc_spawner = %{id: 1, spawn_interval: 0}

      state = %State{
        room_id: 1,
        npc: npc,
        npc_spawner: npc_spawner,
        is_targeting: MapSet.new(),
        continuous_effects: [effect],
      }

      @room.clear_leaves()

      %{state: state, effect: effect}
    end

    test "finds the matching effect and applies it as damage, then decrements the counter", %{state: state, effect: effect} do
      state = Actions.handle_continuous_effect(state, :id)

      effect_id = effect.id
      assert [%{id: :id, count: 2}] = state.continuous_effects
      assert state.npc.stats.health == 15
      assert_receive {:continuous_effect, ^effect_id}
    end

    test "handles death", %{state: state, effect: effect} do
      effect = %{effect | amount: 26}
      state = %{state | continuous_effects: [effect]}

      state = Actions.handle_continuous_effect(state, :id)

      assert [{1, {:npc, _}, :death}] = @room.get_leaves()
      assert state.continuous_effects == []
    end

    test "does not send another message if last count", %{state: state, effect: effect} do
      effect = %{effect | count: 1}
      state = %{state | continuous_effects: [effect]}

      state = Actions.handle_continuous_effect(state, :id)

      effect_id = effect.id
      assert [] = state.continuous_effects
      refute_receive {:continuous_effect, ^effect_id}
    end

    test "does nothing if effect is not found", %{state: state} do
      ^state = Actions.handle_continuous_effect(state, :notfound)
    end
  end
end
