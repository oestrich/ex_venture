defmodule Game.NPC.Actions do
  @moduledoc """
  """

  @rand Application.get_env(:ex_venture, :game)[:rand]

  use Game.Room

  alias Game.Character
  alias Game.Items
  alias Game.Message

  @doc """
  Respawn the NPC as a tick happens
  """
  @spec tick(state :: map, time :: DateTime.t) :: :ok | {:update, map}
  def tick(state = %{npc: %{stats: %{health: health}}}, time) when health < 1 do
    state = state |> handle_respawn(time)
    {:update, state}
  end
  def tick(_state, _time), do: :ok

  defp handle_respawn(state = %{respawn_at: respawn_at, npc: npc, npc_spawner: npc_spawner}, time) when respawn_at != nil do
    case Timex.after?(time, respawn_at) do
      true ->
        npc = %{npc | stats: %{npc.stats | health: npc.stats.max_health}}
        npc_spawner.room_id |> @room.enter({:npc, npc})
        %{state | npc: npc, respawn_at: nil}
      false -> state
    end
  end
  defp handle_respawn(state, time) do
    Map.put(state, :respawn_at, time |> Timex.shift(seconds: state.npc_spawner.spawn_interval))
  end

  @doc """
  Check if the NPC died, and if so perform actions
  """
  @spec maybe_died(stats :: map, state :: map) :: :ok
  def maybe_died(stats, state)
  def maybe_died(%{health: health}, state) when health < 1, do: died(state)
  def maybe_died(_stats, _state), do: :ok

  @doc """
  The NPC died, send out messages
  """
  @spec died(state :: map) :: :ok
  def died(%{npc_spawner: npc_spawner, npc: npc, is_targeting: is_targeting}) do
    npc_spawner.room_id |> @room.say(npc, Message.npc(npc, "I died!"))
    Enum.each(is_targeting, &(Character.died(&1, {:npc, npc})))
    npc_spawner.room_id |> @room.leave({:npc, npc})

    drop_items(npc_spawner.room_id, npc, npc.item_ids)

    :ok
  end

  def drop_items(room_id, npc, item_ids) do
    item_ids
    |> Items.items()
    |> Enum.filter(&drop_item?/1)
    |> Enum.each(fn (item) ->
      room_id |> @room.drop({:npc, npc}, item)
    end)
  end

  def drop_item?(item, rand \\ @rand)
  def drop_item?(%{drop_rate: drop_rate}, rand) do
    rand.uniform(100) <= drop_rate
  end
end
