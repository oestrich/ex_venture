defmodule Game.Channel.Server do
  @moduledoc """
  Server implementation details
  """

  require Logger

  alias Game.Channel

  @doc """
  Get a list of channels the pid is subscribed to
  """
  @spec subscribed_channels(Channel.state(), pid()) :: [String.t()]
  def subscribed_channels(state, pid)
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
  @spec join_channel(Channel.state(), String.t(), pid()) :: Channel.state()
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
  @spec leave_channel(Channel.state(), String.t(), pid()) :: Channel.state()
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
  @spec broadcast(Channel.state(), String.t(), Message.t()) :: :ok
  def broadcast(state, channel, message)
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
  @spec tell(Channel.state(), User.t(), User.t(), Message.t()) :: :ok
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
  @spec process_died(Channel.state(), pid()) :: Channel.state()
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
