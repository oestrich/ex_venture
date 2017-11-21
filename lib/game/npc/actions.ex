defmodule Game.NPC.Actions do
  @moduledoc """
  NPC Actions
  """

  @rand Application.get_env(:ex_venture, :game)[:rand]

  use Game.Room

  require Logger

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
        %{state | npc: npc, room_id: npc_spawner.room_id, respawn_at: nil}
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
  def maybe_died(_stats, state), do: state

  @doc """
  The NPC died, send out messages
  """
  @spec died(state :: map) :: :ok
  def died(state = %{room_id: room_id, npc: npc, is_targeting: is_targeting}) do
    Logger.info("NPC (#{npc.id}) died", type: :npc)

    room_id |> @room.say(npc, Message.npc(npc, "I died!"))
    Enum.each(is_targeting, &(Character.died(&1, {:npc, npc})))
    room_id |> @room.leave({:npc, npc})

    drop_currency(room_id, npc, npc.currency)
    drop_items(room_id, npc, npc.item_ids)

    state
    |> Map.put(:target, nil)
  end

  @doc """
  Drop any currency into the room

  Only when above 0
  """
  @spec drop_currency(room_id :: integer, npc :: NPC.t, currency :: integer) :: :ok
  def drop_currency(room_id, npc, currency) do
    currency = currency |> currency_amount_to_drop()
    case currency do
      currency when currency > 0 ->
        room_id |> @room.drop_currency({:npc, npc}, currency)
      _ -> nil
    end
  end

  @doc """
  Determine how much of the currency should be dropped

  Uses `:rand` by default
  """
  @spec currency_amount_to_drop(item :: Item.t, rand :: atom) :: integer
  def currency_amount_to_drop(currency, rand \\ @rand) do
    percentage_to_drop = (rand.uniform(50) + 50) / 100.0
    round(Float.ceil(currency * percentage_to_drop))
  end

  @doc """
  Drop items into the room with a random chance
  """
  @spec drop_items(room_id :: integer, npc :: NPC.t, item_ids :: [integer]) :: :ok
  def drop_items(room_id, npc, item_ids) do
    item_ids
    |> Items.items()
    |> Enum.filter(&drop_item?/1)
    |> Enum.each(fn (item) ->
      room_id |> @room.drop({:npc, npc}, item)
    end)
  end

  @doc """
  Determine if the item should be dropped

  Uses `:rand` by default
  """
  @spec drop_item?(item :: Item.t, rand :: atom) :: boolean
  def drop_item?(item, rand \\ @rand)
  def drop_item?(%{drop_rate: drop_rate}, rand) do
    rand.uniform(100) <= drop_rate
  end
end
