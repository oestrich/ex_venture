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

  alias Data.User
  alias Game.Message

  require Logger

  defstruct [:channels, :tells]

  @type t :: %__MODULE__{}

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
  @spec join(channel :: String.t) :: :ok
  def join(channel) do
    GenServer.cast(__MODULE__, {:join, channel, self()})
  end

  @doc """
  Join the user's private tell channel
  """
  @spec join_tell(user :: User.t) :: :ok
  def join_tell(user) do
    GenServer.cast(__MODULE__, {:join_tell, self(), user})
  end

  @doc """
  Leave a channel

  The current process PID will leave
  """
  @spec leave(channel :: String.t) :: :ok
  def leave(channel) do
    GenServer.cast(__MODULE__, {:leave, channel, self()})
  end

  @doc """
  Broadcast a message to a channel
  """
  @spec broadcast(channel :: String.t, message :: String.t) :: :ok
  def broadcast(channel, message) do
    GenServer.cast(__MODULE__, {:broadcast, channel, message})
  end

  @doc """
  Tell a message to a user
  """
  @spec tell(user :: User.t, from :: User.t, message :: String.t) :: :ok
  def tell(user, from, message) do
    GenServer.cast(__MODULE__, {:tell, user, from, message})
  end

  @doc """
  List out the subscribed channels

  The current process PID will be used
  """
  @spec subscribed() :: [String.t]
  def subscribed() do
    GenServer.call(__MODULE__, :subscribed)
  end

  #
  # Server
  #

  def init(_) do
    Process.flag(:trap_exit, true)
    {:ok, %__MODULE__{channels: %{}, tells: %{}}}
  end

  def handle_call(:subscribed, {pid, _}, state) do
    channels = subscribed_channels(state, pid)
    {:reply, channels, state}
  end

  def handle_cast({:join, channel, pid}, state) do
    state = join_channel(state, channel, pid)
    {:noreply, state}
  end

  def handle_cast({:join_tell, pid, user}, state = %{tells: tells}) do
    tells = Map.put(tells, "tells:#{user.id}", pid)
    {:noreply, Map.put(state, :tells, tells)}
  end

  def handle_cast({:leave, channel, pid}, state) do
    state = leave_channel(state, channel, pid)
    {:noreply, state}
  end

  def handle_cast({:broadcast, channel, message}, state) do
    broadcast(state, channel, message)
    {:noreply, state}
  end

  def handle_cast({:tell, user, from, message}, state) do
    tell(state, user, from, message)
    {:noreply, state}
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    state = process_died(state, pid)
    {:noreply, state}
  end

  #
  # Server Implementation
  #

  @doc """
  Get a list of channels the pid is subscribed to
  """
  @spec subscribed_channels(map, pid) :: [String.t]
  def subscribed_channels(%{channels: channels}, pid) do
    channels
    |> Enum.filter(fn ({_channel, pids}) -> Enum.member?(pids, pid) end)
    |> Enum.map(fn ({channel, _pids}) -> channel end)
  end

  @doc """
  Join a channel

  Adds the pid to the channel's list of pids for broadcasting to. Will also send
  back to the process that the join was successful.
  """
  @spec join_channel(t(), String.t, pid) :: t()
  def join_channel(state = %{channels: channels}, channel, pid) do
    Process.link(pid)
    channel_pids = Map.get(channels, channel, [])
    channels = Map.put(channels, channel, [pid | channel_pids])
    send(pid, {:channel, {:joined, channel}})
    Map.put(state, :channels, channels)
  end

  @doc """
  Leave a channel

  Removes the pid from the channel's list of pids. Will also send back to the process
  after the leave was successful.
  """
  @spec leave_channel(t(), String.t(), pid()) :: t()
  def leave_channel(state = %{channels: channels}, channel, pid) do
    channel_pids = channels
    |> Map.get(channel, [])
    |> Enum.reject(&(&1 == pid))
    channels = Map.put(channels, channel, channel_pids)
    send(pid, {:channel, {:left, channel}})
    Map.put(state, :channels, channels)
  end

  @doc """
  Broadcast a message to a channel
  """
  @spec broadcast(t(), String.t(), Message.t()) :: :ok
  def broadcast(%{channels: channels}, channel, message) do
    Logger.info("Channel '#{channel}' message: #{inspect(message)}", type: :channel)

    channels
    |> Map.get(channel, [])
    |> Enum.each(fn (pid) ->
      send(pid, {:channel, {:broadcast, message}})
    end)
  end

  @doc """
  Send a tell to a user

  A message will be sent to the user's session in the form of `{:channel, {:tell, from, message}}`.
  """
  @spec tell(t(), User.t(), User.t(), Message.t()) :: :ok
  def tell(%{tells: tells}, user, from, message) do
    case tells |> Map.get("tells:#{user.id}", nil) do
      nil -> nil
      pid -> send(pid, {:channel, {:tell, from, message}})
    end
  end

  @doc """
  The session process died, due to a crash or the player quitting.

  Leave all channels and their user tell channel.
  """
  @spec process_died(t(), pid()) :: t()
  def process_died(state = %{channels: channels, tells: tells}, pid) do
    channels = Enum.reduce(channels, %{}, fn ({channel, pids}, channels) ->
      pids = pids |> Enum.reject(&(&1 == pid))
      Map.put(channels, channel, pids)
    end)

    tells = tells
    |> Enum.reject(fn ({_, tell_pid}) -> tell_pid == pid end)
    |> Enum.into(%{})

    state
    |> Map.put(:channels, channels)
    |> Map.put(:tells, tells)
  end
end
