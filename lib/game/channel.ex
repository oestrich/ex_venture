defmodule Game.Channel do
  @moduledoc """
  Communication channels.

  The joining process will need to have the following `handle_info` cases set up:
  - `{:channel, {:joined, channel}}`
  - `{:channel, {:left, channel}}`
  - `{:channel, {:broadcast, channel, message}}`
  - `{:channel, {:tell, from, message}}`
  """

  use GenServer

  alias Game.Character
  alias Game.Message
  alias Game.Channel.Server

  defstruct [:channels, :tells]

  @type state :: %__MODULE__{}

  @key :channel

  @doc false
  def pg2_key(), do: @key

  @doc """
  Start the GenServer process for managing channels
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  #
  # Client
  #

  @doc """
  Join a channel

  The current process PID will join
  """
  @spec join(String.t()) :: :ok
  def join(channel) do
    GenServer.cast(__MODULE__, {:join, channel, self()})
  end

  @doc """
  Join the player's private tell channel
  """
  @spec join_tell(Character.t()) :: :ok
  def join_tell(character) do
    GenServer.cast(__MODULE__, {:join_tell, self(), character})
  end

  @doc """
  Leave a channel

  The current process PID will leave
  """
  @spec leave(String.t()) :: :ok
  def leave(channel) do
    GenServer.cast(__MODULE__, {:leave, channel, self()})
  end

  @doc """
  Broadcast a message to a channel
  """
  @spec broadcast(String.t(), Message.t()) :: :ok
  def broadcast(channel, message) do
    GenServer.cast(__MODULE__, {:broadcast, channel, message})
  end

  @doc """
  Tell a message to a player
  """
  @spec tell(Character.t(), Character.t(), Message.t()) :: :ok
  def tell(player, from, message) do
    members = :pg2.get_members(@key)

    Enum.map(members, fn member ->
      GenServer.cast(member, {:tell, player, from, message})
    end)
  end

  @doc """
  List out the subscribed channels

  The current process PID will be used
  """
  @spec subscribed() :: [String.t()]
  def subscribed() do
    GenServer.call(__MODULE__, :subscribed)
  end

  #
  # Server
  #

  @impl GenServer
  def init(_) do
    :ok = :pg2.create(@key)
    :ok = :pg2.join(@key, self())

    Process.flag(:trap_exit, true)
    {:ok, %__MODULE__{channels: %{}, tells: %{}}}
  end

  @impl GenServer
  def handle_call(:subscribed, {pid, _}, state) do
    channels = Server.subscribed_channels(state, pid)
    {:reply, channels, state}
  end

  @impl GenServer
  def handle_cast({:join, channel, pid}, state) do
    state = Server.join_channel(state, channel, pid)
    {:noreply, state}
  end

  def handle_cast({:join_tell, pid, %{type: type, id: id}}, state = %{tells: tells}) do
    tells = Map.put(tells, "tells:#{type}:#{id}", pid)
    {:noreply, Map.put(state, :tells, tells)}
  end

  def handle_cast({:leave, channel, pid}, state) do
    state = Server.leave_channel(state, channel, pid)
    {:noreply, state}
  end

  def handle_cast({:broadcast, channel, message}, state) do
    Server.broadcast(state, channel, message)
    {:noreply, state}
  end

  def handle_cast({:broadcast, channel, message, opts}, state) do
    Server.broadcast(state, channel, message, opts)
    {:noreply, state}
  end

  def handle_cast({:tell, player, from, message}, state) do
    Server.tell(state, player, from, message)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:EXIT, pid, _reason}, state) do
    state = Server.process_died(state, pid)
    {:noreply, state}
  end
end
