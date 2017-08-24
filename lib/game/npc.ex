defmodule Game.NPC do
  @moduledoc """
  Server for an NPC
  """

  use GenServer
  use Game.Room

  alias Data.Repo
  alias Data.NPC

  alias Game.Character
  alias Game.Effect
  alias Game.Message
  alias Game.NPC.Actions

  @doc """
  Starts a new NPC server

  Will have a registered name with the return from `Game.NPC.pid/1`.
  """
  def start_link(npc) do
    GenServer.start_link(__MODULE__, npc, name: pid(npc.id))
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
  @spec all() :: [map]
  def all() do
    NPC |> Repo.all
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
  @spec tick(pid :: pid, time :: DateTime.t) :: :ok
  def tick(pid, time) do
    GenServer.cast(pid, {:tick, time})
  end

  def init(npc) do
    GenServer.cast(self(), :enter)
    {:ok, %{npc: npc, is_targeting: MapSet.new()}}
  end

  def handle_cast(:enter, state = %{npc: npc}) do
    @room.enter(npc.room_id, {:npc, npc})
    {:noreply, state}
  end

  def handle_cast({:heard, message}, state = %{npc: npc}) do
    case message.message do
      "Hello" <> _ ->
        npc.room_id |> @room.say(npc, Message.npc(npc, npc |> message))
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

  #
  # Character callbacks
  #
  def handle_cast({:targeted, {_, player}}, state = %{npc: npc}) do
    npc.room_id |> @room.say(npc, Message.npc(npc, "Why are you targeting me, #{player.name}?"))
    state = Map.put(state, :is_targeting, MapSet.put(state.is_targeting, {:user, player.id}))
    {:noreply, state}
  end
  def handle_cast({:remove_target, player}, state) do
    state = Map.put(state, :is_targeting, MapSet.delete(state.is_targeting, Game.Character.who(player)))
    {:noreply, state}
  end
  def handle_cast({:apply_effects, effects, _from, _description}, state = %{npc: npc, is_targeting: is_targeting}) do
    stats = effects |> Effect.apply(npc.stats)
    case stats do
      %{health: health} when health < 1 ->
        npc.room_id |> @room.say(npc, Message.npc(npc, "I died!"))
        Enum.each(is_targeting, &(Character.died(&1, {:npc, npc})))
        npc.room_id |> @room.leave({:npc, npc})
      _ -> nil
    end
    npc = %{npc | stats: stats}
    {:noreply, Map.put(state, :npc, npc)}
  end
  def handle_cast({:died, _who}, state) do
    {:noreply, state}
  end

  defp message(%{hostile: true}), do: "Die!"
  defp message(%{hostile: false}), do: "How are you?"
end
