defmodule Game.NPC do
  @moduledoc """
  Server for an NPC
  """

  use GenServer
  use Game.Room

  require Logger

  import Ecto.Query

  alias Data.NPCSpawner
  alias Data.Repo
  alias Data.Stats
  alias Game.Character
  alias Game.Effect
  alias Game.Message
  alias Game.NPC.Actions
  alias Game.NPC.Events
  alias Game.Zone

  defmodule State do
    @moduledoc """
    State for the NPC GenServer
    """

    defstruct [:npc_spawner, :npc, :room_id, :is_targeting, :target, :last_controlled_at, continuous_effects: []]

    @type t :: %__MODULE__{}
  end

  @doc """
  Starts a new NPC server

  Will have a registered name with the return from `Game.NPC.pid/1`.
  """
  def start_link(npc_spawner) do
    GenServer.start_link(__MODULE__, npc_spawner, name: pid(npc_spawner.id))
  end

  @doc """
  Helper for determining an NPCs registered process name
  """
  @spec pid(id :: integer()) :: atom
  def pid(id) do
    {:via, Registry, {Game.NPC.Registry, id}}
  end

  @doc """
  Load all NPCs in the database
  """
  @spec for_zone(zone :: Zone.t) :: [map]
  def for_zone(zone) do
    NPCSpawner
    |> where([ns], ns.zone_id == ^zone.id)
    |> preload([:npc])
    |> Repo.all
  end

  @doc """
  Notify the NPC of an action occurring in the room
  """
  @spec notify(id :: integer, action :: tuple) :: :ok
  def notify(pid, action) when is_pid(pid) do
    GenServer.cast(pid, {:notify, action})
  end
  def notify(id, action) do
    GenServer.cast(pid(id), {:notify, action})
  end

  @doc """
  Send a tick message
  """
  @spec tick(id :: integer, time :: DateTime.t) :: :ok
  def tick(id, time) do
    GenServer.cast(pid(id), {:tick, time})
  end

  @doc """
  Update a npc's data
  """
  @spec update(id :: integer, npc_spawner :: NPCSpawner.t) :: :ok
  def update(id, npc_spawner) do
    GenServer.cast(pid(id), {:update, npc_spawner})
  end

  @doc """
  """
  @spec terminate(id :: integer) :: :ok
  def terminate(id) do
    GenServer.cast(pid(id), :terminate)
  end

  @doc """
  Have an admin take control of an NPC
  """
  @spec control(id :: integer) :: :ok | {:error, :already_controlled}
  def control(id) do
    GenServer.call(pid(id), :control)
  end

  @doc """
  Have an admin release control of an NPC
  """
  @spec release(id :: integer) :: :ok
  def release(id) do
    GenServer.cast(pid(id), :release)
  end

  @doc """
  Make the NPC say something
  """
  @spec say(id :: integer, message :: String.t) :: :ok
  def say(id, message) do
    GenServer.cast(pid(id), {:say, message})
  end

  @doc """
  Make the NPC emote something
  """
  @spec emote(id :: integer, message :: String.t) :: :ok
  def emote(id, message) do
    GenServer.cast(pid(id), {:emote, message})
  end

  @doc """
  For testing purposes, get the server's state
  """
  def _get_state(id) do
    GenServer.call(pid(id), :get_state)
  end

  #
  # Server
  #

  def init(npc_spawner) do
    npc = %{npc_spawner.npc | id: npc_spawner.id}
    npc = %{npc | stats: Stats.default(npc.stats)}
    Logger.info("Starting NPC #{npc.id}", type: :npc)
    npc_spawner.zone_id |> Zone.npc_online(npc)
    GenServer.cast(self(), :enter)
    {:ok, %State{npc_spawner: npc_spawner, npc: npc, room_id: npc_spawner.room_id, is_targeting: MapSet.new()}, target: nil}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:control, _from, state) do
    case state.last_controlled_at do
      nil -> {:reply, :ok, %{state | last_controlled_at: Timex.now()}}
      _ -> {:reply, {:error, :already_controlled}, state}
    end
  end

  def handle_call(:info, _from, state) do
    {:reply, {:npc, state.npc}, state}
  end

  def handle_cast(:release, state) do
    {:noreply, %{state | last_controlled_at: nil}}
  end

  def handle_cast(:enter, state = %{room_id: room_id, npc: npc}) do
    @room.enter(room_id, {:npc, npc})
    {:noreply, state}
  end

  def handle_cast({:notify, action}, state) do
    case Events.act_on(state, action) do
      :ok -> {:noreply, state}
      {:update, state} -> {:noreply, state}
    end
  end

  def handle_cast({:tick, time}, state) do
    notify(self(), {"tick"})

    case Actions.tick(state, time) do
      :ok -> {:noreply, state}
      {:update, state} -> {:noreply, state}
    end
  end

  def handle_cast({:update, npc_spawner}, state = %{room_id: room_id}) do
    state = state
    |> Map.put(:npc_spawner, npc_spawner)
    |> Map.put(:npc, %{npc_spawner.npc | id: npc_spawner.id})
    @room.update_character(room_id, {:npc, state.npc})
    Logger.info("Updating NPC (#{npc_spawner.id})", type: :npc)
    {:noreply, state}
  end

  def handle_cast({:say, message}, state = %{npc: npc, room_id: room_id}) do
    room_id |> @room.say(npc, Message.npc(npc, message))
    {:noreply, state}
  end

  def handle_cast({:emote, message}, state = %{npc: npc, room_id: room_id}) do
    room_id |> @room.emote(npc, Message.npc_emote(npc, message))
    {:noreply, state}
  end

  #
  # Character callbacks
  #

  def handle_cast({:targeted, player}, state) do
    state = Map.put(state, :is_targeting, MapSet.put(state.is_targeting, Game.Character.who(player)))
    {:noreply, state}
  end

  def handle_cast({:remove_target, player}, state) do
    state = Map.put(state, :is_targeting, MapSet.delete(state.is_targeting, Game.Character.who(player)))
    {:noreply, state}
  end

  def handle_cast({:apply_effects, effects, from, _description}, state = %{npc: npc}) do
    Logger.info("Applying effects to NPC (#{npc.id}) from (#{elem(from, 0)}, #{elem(from, 1).id})", type: :npc)
    continuous_effects = effects |> Effect.continuous_effects()
    stats = effects |> Effect.apply(npc.stats)
    state = stats |> Actions.maybe_died(state)
    npc = %{npc | stats: stats}

    Enum.each(continuous_effects, fn (effect) ->
      :erlang.send_after(effect.every, self(), {:continuous_effect, effect.id})
    end)

    state =
      state
      |> Map.put(:npc, npc)
      |> Map.put(:continuous_effects, continuous_effects ++ state.continuous_effects)

    {:noreply, state}
  end

  def handle_cast({:died, who}, state = %{target: target, npc: npc}) do
    case Character.who(target) == Character.who(who) do
      true ->
        Character.remove_target(target, {:npc, npc})
        {:noreply, Map.put(state, :target, nil)}
      false ->
        {:noreply, state}
    end
  end

  def handle_cast(:terminate, state = %{room_id: room_id, npc: npc, is_targeting: is_targeting}) do
    Enum.each(is_targeting, &(Character.died(&1, {:npc, npc})))
    room_id |> @room.leave({:npc, npc})
    {:stop, :normal, state}
  end

  def handle_info({:continuous_effect, effect_id}, state) do
    state = Actions.continuous_effects(state, effect_id)
    {:noreply, state}
  end
end
