defmodule Game.NPC.ActionsTest do
  use ExUnit.Case
  import Test.ItemsHelper

  alias Game.NPC.Actions

  @room Test.Game.Room

  describe "tick - respawning the npc" do
    setup do
      @room.clear_enters()

      %{time: Timex.now(), npc_spawner: %{room_id: 1, spawn_interval: 10}, npc: %{id: 1, stats: %{health: 10, max_health: 15}}}
    end

    test "does nothing if the npc is alive", %{time: time, npc: npc} do
      :ok = Actions.tick(%{npc: npc}, time)
    end

    test "detecting death", %{time: time, npc_spawner: npc_spawner, npc: npc} do
      {:update, state} = Actions.tick(%{npc: put_in(npc, [:stats, :health], 0), npc_spawner: npc_spawner}, time)
      assert state.respawn_at == time |> Timex.shift(seconds: 10)
    end

    test "doesn't spawn until time", %{time: time, npc_spawner: npc_spawner, npc: npc} do
      respawn_at = time |> Timex.shift(seconds: 2)
      {:update, state} = Actions.tick(%{npc: put_in(npc, [:stats, :health], 0), npc_spawner: npc_spawner, respawn_at: respawn_at}, time)
      assert state.respawn_at == respawn_at
      assert state.npc.stats.health == 0
    end

    test "respawns the npc", %{time: time, npc_spawner: npc_spawner, npc: npc} do
      respawn_at = time |> Timex.shift(seconds: -31)
      {:update, state} = Actions.tick(%{npc: put_in(npc, [:stats, :health], 0), npc_spawner: npc_spawner, respawn_at: respawn_at}, time)
      assert is_nil(state.respawn_at)
      assert state.npc.stats.health == 15
      assert [{1, {:npc, _}}] = @room.get_enters()
    end
  end

  describe "dying" do
    setup do
      @room.clear_drop_currencies()
      @room.clear_drops()

      start_and_clear_items()
      insert_item(%{id: 1, name: "Sword", keywords: [], drop_rate: 50})
      insert_item(%{id: 2, name: "Shield", keywords: [], drop_rate: 50})

      %{npc_spawner: %{room_id: 1}, npc: %{id: 1, name: "NPC", currency: 100, item_ids: [1, 2]}, is_targeting: []}
    end

    test "drops currency in the room", state do
      :ok = Actions.died(state)

      assert [{1, {:npc, _}, 51}] = @room.get_drop_currencies()
    end

    test "does not drop 0 currency", state do
      npc = %{state.npc | currency: 0}
      :ok = Actions.died(%{state | npc: npc})

      assert [] = @room.get_drop_currencies()
    end

    test "will drop an amount 50-100% of the total currency" do
      assert Actions.currency_amount_to_drop(100, Test.DropCurrency) == 80
    end

    test "drops items in the room", state do
      :ok = Actions.died(state)

      assert [{1, {:npc, _}, %{id: 1}}, {1, {:npc, _}, %{id: 2}}] = @room.get_drops()
    end

    test "will drop an item if the chance is below the item's drop rate" do
      assert Actions.drop_item?(%{drop_rate: 50}, Test.DropChanceSuccess)
    end

    test "will not drop an item if the chance is above the item's drop rate" do
      refute Actions.drop_item?(%{drop_rate: 50}, Test.DropChanceFail)
    end
  end
end
