defmodule Game.NPC.Character do
  @moduledoc """
  NPC Character functions
  """

  @rand Application.get_env(:ex_venture, :game)[:rand]

  import Game.Character.Helpers, only: [update_effect_count: 2, is_alive?: 1]

  require Logger

  alias Data.Item
  alias Data.NPC
  alias Game.Character
  alias Game.Character.Effects
  alias Game.Effect
  alias Game.Environment
  alias Game.Events.CharacterDied
  alias Game.Events.RoomEntered
  alias Game.Items
  alias Game.NPC.Events
  alias Game.NPC.Status

  @doc """
  Clean up conversation state, after 5 minutes remove the state of the player
  """
  def clean_conversations(state, time) do
    conversations =
      state.conversations
      |> Enum.filter(fn {_player, conversation} ->
        Timex.after?(conversation.started_at, time |> Timex.shift(minutes: -5))
      end)
      |> Enum.into(%{})

    %{state | conversations: conversations}
  end

  def handle_respawn(state = %{npc: npc, npc_spawner: npc_spawner}) do
    npc = %{npc | stats: %{npc.stats | health_points: npc.stats.max_health_points}}
    status = %Status{key: "start", line: npc.status_line, listen: npc.status_listen}

    npc_spawner.room_id |> Environment.enter({:npc, npc}, :respawn)
    npc_spawner.room_id |> Environment.link()

    {:ok, room} = Environment.look(npc_spawner.room_id)

    Enum.each(room.players, fn player ->
      event = %RoomEntered{character: {:player, player}}
      GenServer.cast(self(), {:notify, event})
    end)

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

    event = %CharacterDied{character: {:npc, npc}, killer: who}
    room_id |> Environment.notify({:npc, npc}, event)

    room_id |> Environment.leave({:npc, npc}, :death)
    room_id |> Environment.unlink()

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
        room_id |> Environment.drop_currency({:npc, npc}, currency)

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
      room_id |> Environment.drop({:npc, npc}, Item.instantiate(item))
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
    {stats, _effects, continuous_effects} =
      Effects.apply_effects({:npc, npc}, npc.stats, state, effects, from)

    npc = Map.put(npc, :stats, stats)
    state = %{state | npc: npc}

    state = stats |> maybe_died(state, from)

    case is_alive?(npc) do
      true ->
        state |> Map.put(:continuous_effects, continuous_effects ++ state.continuous_effects)

      false ->
        state |> Map.put(:continuous_effects, [])
    end
  end

  @doc """
  Find and apply a continuous effect to an NPC
  """
  def handle_continuous_effect(state, effect_id) do
    case Effect.find_effect(state, effect_id) do
      {:ok, effect} ->
        apply_continuous_effect(state, effect)

      {:error, :not_found} ->
        state
    end
  end

  @doc """
  Apply a continuous effect to an NPC
  """
  @spec apply_continuous_effect(State.t(), {Character.t(), Effect.t()}) :: State.t()
  def apply_continuous_effect(state = %{npc: npc}, {from, effect}) do
    {stats, _effects} = Effects.apply_continuous_effect(npc.stats, state, effect)

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
