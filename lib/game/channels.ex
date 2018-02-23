defmodule Game.Channels do
  @moduledoc """
  Agent for keeping track of channels in the system
  """

  use GenServer

  alias Data.Channel
  alias Data.Repo

  @cache :channels

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Insert a new channel into the loaded data
  """
  @spec insert(Channel.t()) :: :ok
  def insert(channel) do
    GenServer.call(__MODULE__, {:insert, channel})
  end

  @doc """
  Trigger an channel reload
  """
  @spec reload(Channel.t()) :: :ok
  def reload(channel), do: insert(channel)

  @doc """
  Get the current set of channels
  """
  @spec get_channels() :: [String.t()]
  def get_channels() do
    case Cachex.get(@cache, :channels) do
      {:ok, channels} when channels != nil ->
        channels

      _ ->
        []
    end
  end

  @doc """
  For testing only: clear the EST table
  """
  def clear() do
    Cachex.clear(@cache)
  end

  #
  # Server
  #

  def init(_) do
    GenServer.cast(self(), :load_channels)
    {:ok, %{}}
  end

  def handle_cast(:load_channels, state) do
    channels =
      Channel
      |> Repo.all()
      |> Enum.map(& &1.name)

    Cachex.set(@cache, :channels, channels)

    {:noreply, state}
  end

  def handle_call({:insert, channel}, _from, state) do
    channels = [channel.name | get_channels()]

    Cachex.set(@cache, :channels, channels)

    {:reply, :ok, state}
  end
end
