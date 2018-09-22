defmodule Game.NPC do
  @moduledoc """
  Server for an NPC
  """

  use GenServer
  use Game.Environment

  require Logger

  alias Data.NPCSpawner
  alias Data.Stats
  alias Game.Channel
  alias Game.Character.Effects
  alias Game.NPC.Actions
  alias Game.NPC.Conversation
  alias Game.NPC.Events
  alias Game.NPC.Repo, as: NPCRepo
  alias Game.NPC.Status
  alias Game.World.Master, as: WorldMaster
  alias Game.Zone
  alias Metrics.NPCInstrumenter

  @key :npcs

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
      :target,
      :last_controlled_at,
      :status,
      combat: false,
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
  def start_link(npc_spawner_id) do
    GenServer.start_link(__MODULE__, npc_spawner_id, name: pid(npc_spawner_id))
  end

  @doc """
  Helper for determining an NPCs registered process name
  """
  @spec pid(integer()) :: atom
  def pid(id) do
    {:global, {Game.NPC, id}}
  end

  @doc """
  Get a simple version of the zone
  """
  def name(id) do
    case Cachex.get(@key, id) do
      {:ok, npc} when npc != nil ->
        {:ok, npc}

      _ ->
        case NPCRepo.get_name(id) do
          {:ok, npc} ->
            Cachex.put(@key, npc.id, npc)
            {:ok, npc}

          {:error, :unknown} ->
            {:error, :unknown}
        end
    end
  end

  @doc """
  Load all NPCs in the database
  """
  @spec for_zone(Zone.t()) :: [integer()]
  def for_zone(zone) do
    NPCRepo.for_zone(zone)
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
  Send a delayed notification, to the same process
  """
  @spec delay_notify(tuple(), Keyword.t()) :: :ok
  def delay_notify(action, milliseconds: ms) do
    Process.send_after(self(), {:notify, action}, ms)
  end

  @doc """
  Update a npc's data
  """
  @spec update(integer, NPCSpawner.t()) :: :ok
  def update(id, npc_spawner) do
    GenServer.cast(pid(id), {:update, npc_spawner})
  end

  @doc """
  Stop an NPC Spawner
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
  def greet(id, player) do
    GenServer.cast(pid(id), {:greet, player})
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

  def init(npc_spawner_id) do
    state = %State{
      npc_spawner: nil,
      npc: nil,
      room_id: nil,
      target: nil,
      combat: false,
      tick_events: []
    }

    {:ok, state, {:continue, {:load, npc_spawner_id}}}
  end

  @doc """
  Load the npc data on start
  """
  def load(npc_spawner_id, state) do
    npc_spawner = NPCRepo.get(npc_spawner_id)

    WorldMaster.update_cache(@key, Map.take(npc_spawner.npc, [:id, :name]))

    npc = customize_npc(npc_spawner, npc_spawner.npc)
    npc = %{npc | stats: Stats.default(npc.stats)}
    status = %Status{key: "start", line: npc.status_line, listen: npc.status_listen}

    npc_spawner.zone_id |> Zone.npc_online(npc)

    Logger.info("Starting NPC #{npc.id}", type: :npc)

    state =
      state
      |> Map.put(:npc_spawner, npc_spawner)
      |> Map.put(:npc, npc)
      |> Map.put(:status, status)
      |> Map.put(:room_id, npc_spawner.room_id)

    GenServer.cast(self(), :enter)

    {:noreply, state}
  end

  def handle_continue({:load, npc_spawner_id}, state), do: load(npc_spawner_id, state)

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
    state = state |> Events.start_tick_events(npc)
    Channel.join_tell({:npc, npc})
    @environment.enter(room_id, {:npc, npc}, :respawn)
    @environment.link(room_id)
    {:noreply, state}
  end

  def handle_cast({:greet, player}, state) do
    state = Conversation.greet(state, player)
    schedule_cleaning_conversations()
    {:noreply, state}
  end

  def handle_cast({:notify, action}, state) do
    case Events.act_on(state, action) do
      :ok ->
        {:noreply, state}

      {:update, state} ->
        {:noreply, state}
    end
  end

  def handle_cast({:act, action}, state) do
    case Events.act(state, action) do
      :ok ->
        {:noreply, state}

      {:update, state} ->
        {:noreply, state}
    end
  end

  def handle_cast({:act, action, actions}, state) do
    case Events.act(state, action, actions) do
      :ok ->
        {:noreply, state}

      {:update, state} ->
        {:noreply, state}
    end
  end

  def handle_cast({:update, npc_spawner}, state = %{room_id: room_id}) do
    WorldMaster.update_cache(@key, npc_spawner.npc)

    state =
      state
      |> Map.put(:npc_spawner, npc_spawner)
      |> Map.put(:npc, customize_npc(npc_spawner, npc_spawner.npc))
      |> Events.start_tick_events(npc_spawner.npc)

    @environment.update_character(room_id, {:npc, state.npc})
    Logger.info("Updating NPC (#{npc_spawner.id})", type: :npc)
    {:noreply, state}
  end

  def handle_cast({:say, message}, state) do
    state |> Events.say_to_room(message)
    {:noreply, state}
  end

  def handle_cast({:emote, message}, state) do
    state |> Events.emote_to_room(message)
    {:noreply, state}
  end

  #
  # Character callbacks
  #

  def handle_cast({:targeted, who}, state) do
    Events.broadcast(state.npc, "combat/targeted", Events.who(who))
    {:noreply, state}
  end

  def handle_cast({:apply_effects, effects, from, description}, state = %{npc: npc}) do
    Logger.info(
      "Applying effects to NPC (#{npc.id}) from (#{elem(from, 0)}, #{elem(from, 1).id})",
      type: :npc
    )

    Events.broadcast(npc, "combat/effects", %{
      from: Events.who(from),
      text: description,
      effects: effects
    })

    state = Actions.apply_effects(state, effects, from)
    {:noreply, state}
  end

  def handle_cast({:effects_applied, _effects, _target}, state) do
    {:noreply, state}
  end

  def handle_cast(:terminate, state = %{room_id: room_id, npc: npc}) do
    room_id |> @environment.leave({:npc, npc}, :leave)
    {:stop, :normal, state}
  end

  def handle_info({:notify, action}, state) do
    handle_cast({:notify, action}, state)
  end

  def handle_info({:tick, event_id}, state) do
    case state.tick_events |> Enum.find(&(&1.id == event_id)) do
      nil ->
        {:noreply, state}

      tick_event ->
        NPCInstrumenter.tick_event_acted_on(tick_event.action.type)

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

  def handle_info({:continuous_effect, :clear, effect_id}, state) do
    state = Effects.clear_continuous_effect(state, effect_id)
    {:noreply, state}
  end

  def handle_info({:conversation, :continue, player}, state) do
    state = Conversation.continue(state, player)
    {:noreply, state}
  end

  def handle_info({:channel, {:tell, {:player, player}, message}}, state) do
    state = Conversation.recv(state, player, message.message)
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
