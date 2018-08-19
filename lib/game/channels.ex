defmodule Game.Channels do
  @moduledoc """
  Agent for keeping track of channels in the system
  """

  use GenServer

  alias Data.Channel
  alias Data.Repo

  @key :channels

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get(channel) do
    _fetch_from_cache(@key, channel)
  end

  @doc """
  Insert a new channel into the loaded data
  """
  @spec insert(Channel.t()) :: :ok
  def insert(channel) do
    members = :pg2.get_members(@key)

    Enum.map(members, fn member ->
      GenServer.call(member, {:insert, channel})
    end)
  end

  @doc """
  Trigger an channel reload
  """
  @spec reload(Channel.t()) :: :ok
  def reload(channel), do: insert(channel)

  @doc """
  Get the current set of channels
  """
  @spec all() :: [String.t()]
  def all() do
    Cachex.execute!(@key, fn cache ->
      {:ok, keys} = Cachex.keys(cache)
      keys = Enum.filter(keys, &is_integer/1)

      channels =
        keys
        |> Enum.map(&_fetch_from_cache(cache, &1))
        |> Enum.reject(&is_nil/1)

      {:ok, channels}
    end)
  end

  @doc """
  Get a list of Gossip connected channels
  """
  @spec gossip_channels() :: [Channel.t()]
  def gossip_channels() do
    Enum.filter(all(), &(&1.is_gossip_connected))
  end

  @doc """
  Match a Gossip channel with a local channel
  """
  @spec gossip_channel(String.t()) :: {:ok, Channel.t()} | {:error, :not_found}
  def gossip_channel(remote_channel) do
    channel =
      all()
      |> Enum.find(fn channel ->
        channel.gossip_channel == remote_channel
      end)

    case channel do
      nil ->
        {:error, :not_found}

      channel ->
        {:ok, channel}
    end
  end

  @doc """
  For testing only: clear the EST table
  """
  def clear() do
    Cachex.clear(@key)
  end

  defp _fetch_from_cache(cache, key) do
    case Cachex.get(cache, key) do
      {:ok, nil} ->
        nil

      {:ok, channel} ->
        channel

      _ ->
        nil
    end
  end

  #
  # Server
  #

  def init(_) do
    :ok = :pg2.create(@key)
    :ok = :pg2.join(@key, self())

    GenServer.cast(self(), :load_channels)

    {:ok, %{}}
  end

  def handle_cast(:load_channels, state) do
    channels = Channel |> Repo.all()

    Enum.each(channels, fn channel ->
      Cachex.put(@key, channel.id, channel)
      Cachex.put(@key, channel.name, channel)
    end)

    {:noreply, state}
  end

  def handle_call({:insert, channel}, _from, state) do
    Cachex.put(@key, channel.id, channel)
    Cachex.put(@key, channel.name, channel)

    {:reply, :ok, state}
  end
end
