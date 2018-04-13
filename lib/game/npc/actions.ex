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
  alias Game.NPC.Events
  alias Game.NPC.Status

  @doc """
  Clean up conversation state, after 5 minutes remove the state of the user
  """
  def clean_conversations(state, time) do
    conversations =
      state.conversations
      |> Enum.filter(fn {_user, conversation} ->
        Timex.after?(conversation.started_at, time |> Timex.shift(minutes: -5))
      end)
      |> Enum.into(%{})

    %{state | conversations: conversations}
  end

  def handle_respawn(state = %{npc: npc, npc_spawner: npc_spawner}) do
    npc = %{npc | stats: %{npc.stats | health_points: npc.stats.max_health_points}}
    status = %Status{key: "start", line: npc.status_line, listen: npc.status_listen}
    npc_spawner.room_id |> @room.enter({:npc, npc}, :respawn)
    Events.broadcast(npc, "character/respawned")
    %{state | npc: npc, status: status, room_id: npc_spawner.room_id}
  end

  @doc """
  Check if the NPC died, and if so perform actions
  """
  @spec maybe_died(map, map, Character.t()) :: :ok
  def maybe_died(stats, state, from)

  def maybe_died(%{health_points: health_points}, state, from) when health_points < 1,
    do: died(state, from)

  def maybe_died(_stats, state, _from), do: state

  @doc """
  The NPC died, send out messages
  """
  @spec died(map, Character.t()) :: :ok
  def died(state = %{room_id: room_id, npc: npc, npc_spawner: npc_spawner}, who) do
    Logger.info("NPC (#{npc.id}) died", type: :npc)

    room_id |> @room.notify({:npc, npc}, {"character/died", {:npc, npc}, :character, who})
    room_id |> @room.leave({:npc, npc}, :death)

    Events.broadcast(npc, "character/died")

    drop_currency(room_id, npc, npc.currency)
    npc |> drop_items(room_id)

    :erlang.send_after(npc_spawner.spawn_interval * 1000, self(), :respawn)

    state
    |> Map.put(:target, nil)
    |> Map.put(:continuous_effects, [])
  end

  @doc """
  Drop any currency into the room

  Only when above 0
  """
  @spec drop_currency(integer, NPC.t(), integer) :: :ok
  def drop_currency(room_id, npc, currency) do
    currency = currency |> currency_amount_to_drop()

    case currency do
      currency when currency > 0 ->
        room_id |> @room.drop_currency({:npc, npc}, currency)

      _ ->
        nil
    end
  end

  @doc """
  Determine how much of the currency should be dropped

  Uses `:rand` by default
  """
  @spec currency_amount_to_drop(Item.t(), atom) :: integer
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
    |> Enum.map(fn npc_item ->
      item = Items.item(npc_item.item_id)
      room_id |> @room.drop({:npc, npc}, Item.instantiate(item))
    end)
  end

  @doc """
  Determine if the item should be dropped

  Uses `:rand` by default
  """
  @spec drop_item?(NPCItem.t(), atom) :: boolean
  def drop_item?(npc_item, rand \\ @rand)

  def drop_item?(%{drop_rate: drop_rate}, rand) do
    rand.uniform(100) <= drop_rate
  end

  @doc """
  Apply effects to the NPC
  """
  @spec apply_effects(State.t(), [Effect.t()], tuple()) :: State.t()
  def apply_effects(state = %{npc: npc}, effects, from) do
    effects = effects |> Effect.adjust_effects(npc.stats)
    continuous_effects = effects |> Effect.continuous_effects(from)
    stats = effects |> Effect.apply(npc.stats)
    from |> Character.effects_applied(effects, {:npc, npc})
    state = stats |> maybe_died(state, from)

    npc = %{npc | stats: stats}
    state = %{state | npc: npc}

    Enum.each(continuous_effects, fn {_, effect} ->
      :erlang.send_after(effect.every, self(), {:continuous_effect, effect.id})
    end)

    case is_alive?(npc) do
      true ->
        state |> Map.put(:continuous_effects, continuous_effects ++ state.continuous_effects)

      false ->
        state |> Map.put(:continuous_effects, [])
    end
  end

  @doc """
  Apply a continuous effect to an NPC
  """
  def handle_continuous_effect(state, effect_id) do
    case Enum.find(state.continuous_effects, fn {_from, effect} -> effect.id == effect_id end) do
      nil -> state
      effect -> apply_continuous_effect(state, effect)
    end
  end

  @doc """
  """
  @spec apply_continuous_effect(State.t(), {Character.t(), Effect.t()}) :: State.t()
  def apply_continuous_effect(state = %{npc: npc}, {from, effect}) do
    effects = [effect] |> Effect.adjust_effects(npc.stats)
    stats = effects |> Effect.apply(npc.stats)
    state = stats |> maybe_died(state, from)
    npc = %{npc | stats: stats}
    state = %{state | npc: npc}

    case is_alive?(npc) do
      true ->
        state |> update_effect_count({from, effect})

      false ->
        state
    end
  end
end
