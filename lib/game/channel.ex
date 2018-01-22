defmodule Game.Channel do
  @moduledoc """
  Communication channels.

  The joining process will need to have the following `handle_info` cases set up:
  - `{:channel, {:joined, channel}}`
  - `{:channel, {:left, channel}}`
  - `{:channel, {:broadcast, message}}`
  - `{:channel, {:tell, from, message}}`
  """

  use GenServer

  alias Game.Character
  alias Game.Message
  alias Game.Channel.Server

  defstruct [:channels, :tells]

  @type state :: %__MODULE__{}

  @doc """
  Start the GenServer process for managing channels
  """
  @spec start_link() :: {:ok, pid()}
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
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
  Join the user's private tell channel
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
  Tell a message to a user
  """
  @spec tell(Character.t(), Character.t(), Message.t()) :: :ok
  def tell(user, from, message) do
    GenServer.cast(__MODULE__, {:tell, user, from, message})
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

  def handle_cast({:join_tell, pid, {type, who}}, state = %{tells: tells}) do
    tells = Map.put(tells, "tells:#{type}:#{who.id}", pid)
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

  def handle_cast({:tell, user, from, message}, state) do
    Server.tell(state, user, from, message)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:EXIT, pid, _reason}, state) do
    state = Server.process_died(state, pid)
    {:noreply, state}
  end
end
