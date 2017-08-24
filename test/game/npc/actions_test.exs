defmodule Game.NPC.ActionsTest do
  use ExUnit.Case

  alias Game.NPC.Actions

  @room Test.Game.Room

  describe "tick - respawning the npc" do
    setup do
      %{time: Timex.now(), npc: %{room_id: 1, stats: %{health: 10, max_health: 15}, spawn_interval: 10}}
    end

    test "does nothing if the npc is alive", %{time: time, npc: npc} do
      :ok = Actions.tick(%{npc: npc}, time)
    end

    test "detecting death", %{time: time, npc: npc} do
      {:update, state} = Actions.tick(%{npc: put_in(npc, [:stats, :health], 0)}, time)
      assert state.respawn_at == time |> Timex.shift(seconds: 10)
    end

    test "doesn't spawn until time", %{time: time, npc: npc} do
      respawn_at = time |> Timex.shift(seconds: 2)
      {:update, state} = Actions.tick(%{npc: put_in(npc, [:stats, :health], 0), respawn_at: respawn_at}, time)
      assert state.respawn_at == respawn_at
      assert state.npc.stats.health == 0
    end

    test "respawns the npc", %{time: time, npc: npc} do
      respawn_at = time |> Timex.shift(seconds: -31)
      {:update, state} = Actions.tick(%{npc: put_in(npc, [:stats, :health], 0), respawn_at: respawn_at}, time)
      assert is_nil(state.respawn_at)
      assert state.npc.stats.health == 15
      assert [{1, {:npc, _}}] = @room.get_enters()
    end
  end
end
