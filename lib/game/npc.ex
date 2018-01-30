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
  alias Game.Channel
  alias Game.Character
  alias Game.Message
  alias Game.NPC.Actions
  alias Game.NPC.Conversation
  alias Game.NPC.Events
  alias Game.Zone

  defmacro __using__(_opts) do
    quote do
      @npc Application.get_env(:ex_venture, :game)[:npc]
    end
  end

  defmodule State do
    @moduledoc """
    State for the NPC GenServer
    """

    defstruct [
      :npc_spawner,
      :npc,
      :room_id,
      :is_targeting,
      :target,
      :last_controlled_at,
      tick_events: [],
      conversations: %{},
      continuous_effects: []
    ]

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
  @spec pid(integer()) :: atom
  def pid(id) do
    {:via, Registry, {Game.NPC.Registry, id}}
  end

  @doc """
  Load all NPCs in the database
  """
  @spec for_zone(Zone.t()) :: [map]
  def for_zone(zone) do
    NPCSpawner
    |> where([ns], ns.zone_id == ^zone.id)
    |> preload(npc: [:npc_items])
    |> Repo.all()
  end

  @doc """
  Notify the NPC of an action occurring in the room
  """
  @spec notify(integer, tuple) :: :ok
  def notify(pid, action) when is_pid(pid) do
    GenServer.cast(pid, {:notify, action})
  end

  def notify(id, action) do
    GenServer.cast(pid(id), {:notify, action})
  end

  @doc """
  Update a npc's data
  """
  @spec update(integer, NPCSpawner.t()) :: :ok
  def update(id, npc_spawner) do
    GenServer.cast(pid(id), {:update, npc_spawner})
  end

  @doc """
  """
  @spec terminate(integer) :: :ok
  def terminate(id) do
    GenServer.cast(pid(id), :terminate)
  end

  @doc """
  Have an admin take control of an NPC
  """
  @spec control(integer) :: :ok | {:error, :already_controlled}
  def control(id) do
    GenServer.call(pid(id), :control)
  end

  @doc """
  Have an admin release control of an NPC
  """
  @spec release(integer) :: :ok
  def release(id) do
    GenServer.cast(pid(id), :release)
  end

  @doc """
  Make the NPC say something
  """
  @spec say(integer, String.t()) :: :ok
  def say(id, message) do
    GenServer.cast(pid(id), {:say, message})
  end

  @doc """
  Make the NPC emote something
  """
  @spec emote(integer, String.t()) :: :ok
  def emote(id, message) do
    GenServer.cast(pid(id), {:emote, message})
  end

  @doc """
  Greet an NPC
  """
  @spec greet(integer(), User.t()) :: :ok
  def greet(id, user) do
    GenServer.cast(pid(id), {:greet, user})
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
    npc = customize_npc(npc_spawner, npc_spawner.npc)
    npc = %{npc | stats: Stats.default(npc.stats)}
    Logger.info("Starting NPC #{npc.id}", type: :npc)
    npc_spawner.zone_id |> Zone.npc_online(npc)
    GenServer.cast(self(), :enter)

    state = %State{
      npc_spawner: npc_spawner,
      npc: npc,
      room_id: npc_spawner.room_id,
      is_targeting: MapSet.new(),
      target: nil,
      tick_events: [],
    }

    state = state |> Events.start_tick_events(npc)

    {:ok, state}
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
    Channel.join_tell({:npc, npc})
    @room.enter(room_id, {:npc, npc})
    {:noreply, state}
  end

  def handle_cast({:greet, user}, state) do
    state = Conversation.greet(state, user)
    schedule_cleaning_conversations()
    {:noreply, state}
  end

  def handle_cast({:notify, action}, state) do
    case Events.act_on(state, action) do
      :ok -> {:noreply, state}
      {:update, state} -> {:noreply, state}
    end
  end

  def handle_cast({:update, npc_spawner}, state = %{room_id: room_id}) do
    state =
      state
      |> Map.put(:npc_spawner, npc_spawner)
      |> Map.put(:npc, customize_npc(npc_spawner, npc_spawner.npc))
      |> Events.start_tick_events(npc_spawner.npc)

    @room.update_character(room_id, {:npc, state.npc})
    Logger.info("Updating NPC (#{npc_spawner.id})", type: :npc)
    {:noreply, state}
  end

  def handle_cast({:say, message}, state = %{npc: npc, room_id: room_id}) do
    room_id |> @room.say({:npc, npc}, Message.npc(npc, message))
    {:noreply, state}
  end

  def handle_cast({:emote, message}, state = %{npc: npc, room_id: room_id}) do
    room_id |> @room.emote({:npc, npc}, Message.npc_emote(npc, message))
    {:noreply, state}
  end

  #
  # Character callbacks
  #

  def handle_cast({:targeted, player}, state) do
    state =
      Map.put(state, :is_targeting, MapSet.put(state.is_targeting, Game.Character.who(player)))

    {:noreply, state}
  end

  def handle_cast({:remove_target, player}, state) do
    state =
      Map.put(state, :is_targeting, MapSet.delete(state.is_targeting, Game.Character.who(player)))

    {:noreply, state}
  end

  def handle_cast({:apply_effects, effects, from, _description}, state = %{npc: npc}) do
    Logger.info(
      "Applying effects to NPC (#{npc.id}) from (#{elem(from, 0)}, #{elem(from, 1).id})",
      type: :npc
    )

    state = Actions.apply_effects(state, effects, from)
    {:noreply, state}
  end

  def handle_cast({:died, _who}, state = %{target: nil}) do
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
    Enum.each(is_targeting, &Character.died(&1, {:npc, npc}))
    room_id |> @room.leave({:npc, npc})
    {:stop, :normal, state}
  end

  def handle_info({:tick, event_id}, state) do
    Logger.debug("NPC #{state.npc.id} received tick for event: #{event_id}", type: :npc)

    case state.tick_events |> Enum.find(&(&1.id == event_id)) do
      nil ->
        {:noreply, state}

      tick_event ->
        state = Events.act_on_tick(state, tick_event)
        tick_event |> Events.delay_event()
        {:noreply, state}
    end
  end

  def handle_info(:respawn, state) do
    {:noreply, Actions.handle_respawn(state)}
  end

  def handle_info(:clean_conversations, state) do
    {:noreply, Actions.clean_conversations(state, Timex.now())}
  end

  def handle_info({:continuous_effect, effect_id}, state) do
    state = Actions.handle_continuous_effect(state, effect_id)
    {:noreply, state}
  end

  def handle_info({:channel, {:tell, {:user, user}, message}}, state) do
    state = Conversation.recv(state, user, message.message)
    schedule_cleaning_conversations()
    {:noreply, state}
  end

  def handle_info({:channel, {:tell, _, _message}}, state) do
    {:noreply, state}
  end

  # clean conversations after 6 minutes, to ensure something will be cleaned
  defp schedule_cleaning_conversations() do
    :erlang.send_after(6 * 60 * 1000, self(), :clean_conversations)
  end

  defp customize_npc(npc_spawner, npc) do
    npc
    |> Map.put(:original_id, npc.id)
    |> Map.put(:id, npc_spawner.id)
    |> maybe_copy_name(npc_spawner)
  end

  defp maybe_copy_name(npc, %{name: name}) do
    case name do
      nil -> npc
      _ -> npc |> Map.put(:name, name)
    end
  end
end
