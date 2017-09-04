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

  #
  # Server
  #

  def init(_) do
    Process.flag(:trap_exit, true)
    {:ok, %{channels: %{}}}
  end

  def handle_cast({:join, channel, pid}, state = %{channels: channels}) do
    Process.link(pid)

    channel_pids = Map.get(channels, channel, [])
    channels = Map.put(channels, channel, [pid | channel_pids])

    send(pid, {:channel, {:joined, channel}})
    {:noreply, Map.put(state, :channels, channels)}
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

  def handle_info({:EXIT, pid, _reason}, state = %{channels: channels}) do
    channels = Enum.reduce(channels, %{}, fn ({channel, pids}, channels) ->
      pids = pids |> Enum.reject(&(&1 == pid))
      Map.put(channels, channel, pids)
    end)
    {:noreply, Map.put(state, :channels, channels)}
  end
end
