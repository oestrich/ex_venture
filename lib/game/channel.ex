defmodule Game.Channel do
  @moduledoc """
  Communication channels
  """

  use GenServer

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
    {:ok, %{channels: %{}, tells: %{}}}
  end

  def handle_call(:subscribed, {pid, _}, state = %{channels: channels}) do
    channels = channels
    |> Enum.filter(fn ({_channel, pids}) -> Enum.member?(pids, pid) end)
    |> Enum.map(fn ({channel, _pids}) -> channel end)
    {:reply, channels, state}
  end

  def handle_cast({:join, channel, pid}, state = %{channels: channels}) do
    Process.link(pid)

    channel_pids = Map.get(channels, channel, [])
    channels = Map.put(channels, channel, [pid | channel_pids])

    send(pid, {:channel, {:joined, channel}})
    {:noreply, Map.put(state, :channels, channels)}
  end

  def handle_cast({:join_tell, pid, user}, state = %{tells: tells}) do
    tells = Map.put(tells, "tells:#{user.id}", pid)
    {:noreply, Map.put(state, :tells, tells)}
  end

  def handle_cast({:leave, channel, pid}, state = %{channels: channels}) do
    channel_pids = channels
    |> Map.get(channel, [])
    |> Enum.reject(&(&1 == pid))

    send(pid, {:channel, {:left, channel}})

    channels = Map.put(channels, channel, channel_pids)
    {:noreply, Map.put(state, :channels, channels)}
  end

  def handle_cast({:broadcast, channel, message}, state = %{channels: channels}) do
    channels
    |> Map.get(channel, [])
    |> Enum.each(fn (pid) ->
      send(pid, {:channel, {:broadcast, message}})
    end)

    {:noreply, state}
  end

  def handle_cast({:tell, user, from, message}, state = %{tells: tells}) do
    case tells |> Map.get("tells:#{user.id}", nil) do
      nil -> nil
      pid -> send(pid, {:channel, {:tell, from, message}})
    end

    {:noreply, state}
  end

  def handle_info({:EXIT, pid, _reason}, state = %{channels: channels, tells: tells}) do
    channels = Enum.reduce(channels, %{}, fn ({channel, pids}, channels) ->
      pids = pids |> Enum.reject(&(&1 == pid))
      Map.put(channels, channel, pids)
    end)

    tells = tells
    |> Enum.reject(fn ({_, tell_pid}) -> tell_pid == pid end)
    |> Enum.into(%{})

    state = state
    |> Map.put(:channels, channels)
    |> Map.put(:tells, tells)

    {:noreply, state}
  end
end
