defmodule Game.NPC.Actions do
  @moduledoc """
  NPC Actions
  """

  @rand Application.get_env(:ex_venture, :game)[:rand]

  use Game.Room

  import Game.Character.Helpers, only: [update_effect_count: 2, is_alive?: 1]

  require Logger

  alias Data.Item
  alias Data.NPC
  alias Game.Character
  alias Game.Effect
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
    npc |> drop_items(room_id)

    state
    |> Map.put(:target, nil)
    |> Map.put(:continuous_effects, [])
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
  @spec drop_items(NPC.t(), integer()) :: :ok
  def drop_items(npc, room_id) do
    npc.npc_items
    |> Enum.filter(&drop_item?/1)
    |> Enum.map(fn (npc_item) ->
      item = Items.item(npc_item.item_id)
      room_id |> @room.drop({:npc, npc}, Item.instantiate(item))
    end)
  end

  @doc """
  Determine if the item should be dropped

  Uses `:rand` by default
  """
  @spec drop_item?(NPCItem.t(), rand :: atom) :: boolean
  def drop_item?(npc_item, rand \\ @rand)
  def drop_item?(%{drop_rate: drop_rate}, rand) do
    rand.uniform(100) <= drop_rate
  end

  @doc """
  Apply effects to the NPC
  """
  @spec apply_effects(State.t, [Effect.t], tuple()) :: State.t
  def apply_effects(state = %{npc: npc}, effects, _from) do
    continuous_effects = effects |> Effect.continuous_effects()
    stats = effects |> Effect.apply(npc.stats)
    state = stats |> maybe_died(state)
    npc = %{npc | stats: stats}
    state = %{state | npc: npc}

    Enum.each(continuous_effects, fn (effect) ->
      :erlang.send_after(effect.every, self(), {:continuous_effect, effect.id})
    end)

    case is_alive?(npc) do
      true -> state |> Map.put(:continuous_effects, continuous_effects ++ state.continuous_effects)
      false -> state |> Map.put(:continuous_effects, [])
    end
  end

  @doc """
  Apply a continuous effect to an NPC
  """
  def handle_continuous_effect(state, effect_id) do
    case Enum.find(state.continuous_effects, &(&1.id == effect_id)) do
      nil -> state
      effect -> apply_continuous_effect(state, effect)
    end
  end

  @doc """
  """
  @spec apply_continuous_effect(State.t, Effect.t) :: State.t
  def apply_continuous_effect(state = %{npc: npc}, effect) do
    stats = [effect] |> Effect.apply(npc.stats)
    state = stats |> maybe_died(state)
    npc = %{npc | stats: stats}
    state = %{state | npc: npc}

    case is_alive?(npc) do
      true ->
        state |> update_effect_count(effect)
      false ->
        state
    end
  end
end
