defmodule Game.Session.Channels do
  @moduledoc """
  Implementation for channel callbacks
  """

  use Networking.Socket

  @doc """
  Call back for joining a channel
  """
  def joined(state = %{save: save}, channel) do
    channels = [channel | save.channels]
    |> Enum.into(MapSet.new)
    |> Enum.into([])

    save = %{save | channels: channels}
    %{state | save: save}
  end

  @doc """
  Callback for leaving a channel
  """
  def left(state = %{save: save}, channel) do
    channels = Enum.reject(save.channels, &(&1 == channel))
    save = %{save | channels: channels}
    %{state | save: save}
  end

  @doc """
  Callback for receiving a broadcast on a channel
  """
  def broadcast(state = %{socket: socket}, message) do
    socket |> @socket.echo(message)
    state
  end

  @doc """
  Callback for receiving a tell
  """
  def tell(state = %{socket: socket}, from, message) do
    socket |> @socket.echo(message)
    Map.put(state, :reply_to, from)
  end
end
