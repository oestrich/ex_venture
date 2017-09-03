defmodule Game.NPC.Actions do
  @moduledoc """
  """

  use Game.Room

  @doc """
  Respawn the NPC as a tick happens
  """
  @spec tick(state :: map, time :: DateTime.t) :: :ok | {:update, map}
  def tick(state = %{npc: %{stats: %{health: health}}}, time) when health < 1 do
    state = state |> handle_respawn(time)
    {:update, state}
  end
  def tick(_state, _time), do: :ok

  defp handle_respawn(state = %{respawn_at: respawn_at, npc: npc, zone_npc: zone_npc}, time) when respawn_at != nil do
    case Timex.after?(time, respawn_at) do
      true ->
        npc = %{npc | stats: %{npc.stats | health: npc.stats.max_health}}
        zone_npc.room_id |> @room.enter({:npc, npc})
        %{state | npc: npc, respawn_at: nil}
      false -> state
    end
  end
  defp handle_respawn(state, time) do
    Map.put(state, :respawn_at, time |> Timex.shift(seconds: state.zone_npc.spawn_interval))
  end
end
