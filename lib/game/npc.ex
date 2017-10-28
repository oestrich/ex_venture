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
  alias Game.Zone

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
  The NPC overheard a message

  Hook to respond to echos
  """
  @spec heard(id :: integer, message :: Message.t) :: :ok
  def heard(id, message) do
    GenServer.cast(pid(id), {:heard, message})
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
    {:ok, %{npc_spawner: npc_spawner, npc: npc, is_targeting: MapSet.new()}}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast(:enter, state = %{npc_spawner: npc_spawner, npc: npc}) do
    @room.enter(npc_spawner.room_id, {:npc, npc})
    {:noreply, state}
  end

  def handle_cast({:heard, message}, state = %{npc_spawner: npc_spawner, npc: npc}) do
    case message.message do
      "Hello" <> _ ->
        npc_spawner.room_id |> @room.say(npc, Message.npc(npc, npc |> message))
      _ -> nil
    end
    {:noreply, state}
  end

  def handle_cast({:tick, time}, state) do
    case Actions.tick(state, time) do
      :ok -> {:noreply, state}
      {:update, state} -> {:noreply, state}
    end
  end

  def handle_cast({:update, npc_spawner}, state) do
    state = state
    |> Map.put(:npc_spawner, npc_spawner)
    |> Map.put(:npc, %{npc_spawner.npc | id: npc_spawner.id})
    @room.update_character(npc_spawner.room_id, {:npc, state.npc})
    Logger.info("Updating NPC (#{npc_spawner.id})", type: :npc)
    {:noreply, state}
  end

  #
  # Character callbacks
  #

  def handle_cast({:targeted, {_, player}}, state = %{npc_spawner: npc_spawner, npc: npc}) do
    npc_spawner.room_id |> @room.say(npc, Message.npc(npc, "Why are you targeting me, #{player.name}?"))
    state = Map.put(state, :is_targeting, MapSet.put(state.is_targeting, {:user, player.id}))
    {:noreply, state}
  end

  def handle_cast({:remove_target, player}, state) do
    state = Map.put(state, :is_targeting, MapSet.delete(state.is_targeting, Game.Character.who(player)))
    {:noreply, state}
  end

  def handle_cast({:apply_effects, effects, from, _description}, state = %{npc: npc}) do
    Logger.info("Applying effects to NPC (#{npc.id}) from (#{elem(from, 0)}, #{elem(from, 1).id})", type: :npc)
    stats = effects |> Effect.apply(npc.stats)
    stats |> Actions.maybe_died(state)
    npc = %{npc | stats: stats}
    {:noreply, Map.put(state, :npc, npc)}
  end

  def handle_cast({:died, _who}, state) do
    {:noreply, state}
  end

  def handle_cast(:terminate, state = %{npc_spawner: npc_spawner, npc: npc, is_targeting: is_targeting}) do
    Enum.each(is_targeting, &(Character.died(&1, {:npc, npc})))
    npc_spawner.room_id |> @room.leave({:npc, npc})
    {:stop, :normal, state}
  end

  defp message(%{hostile: true}), do: "Die!"
  defp message(%{hostile: false}), do: "How are you?"
end
