defmodule Game.Features do
  @moduledoc """
  Agent for keeping track of features in the system
  """

  use GenServer

  alias Data.Feature
  alias Data.Repo

  @key :features

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Load a feature
  """
  def feature(id) when is_integer(id) do
    case Cachex.get(@key, id) do
      {:ok, feature} when feature != nil ->
        feature

      _ ->
        nil
    end
  end

  @doc """
  Convert a list of feature ids to a list of features
  """
  @spec features([integer()]) :: [Feature.t()]
  def features(ids) do
    ids
    |> Enum.map(&feature/1)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Insert a new feature into the cache
  """
  @spec insert(Feature.t()) :: :ok
  def insert(feature) do
    members = :pg2.get_members(@key)

    Enum.map(members, fn member ->
      GenServer.call(member, {:insert, feature})
    end)
  end

  @doc """
  Reload a feature in the cache
  """
  @spec reload(Feature.t()) :: :ok
  def reload(feature), do: insert(feature)

  @doc """
  Remove a feature from the cache
  """
  def remove(feature) do
    members = :pg2.get_members(@key)

    Enum.map(members, fn member ->
      GenServer.call(member, {:remove, feature})
    end)
  end

  @doc """
  For testing only: clear the EST table
  """
  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  #
  # Server
  #

  def init(_) do
    :ok = :pg2.create(@key)
    :ok = :pg2.join(@key, self())

    {:ok, %{}, {:continue, :load_features}}
  end

  def handle_continue(:load_features, state) do
    features = Repo.all(Feature)

    Enum.each(features, fn feature ->
      Cachex.set(@key, feature.id, feature)
    end)

    {:noreply, state}
  end

  def handle_call({:insert, feature}, _from, state) do
    Cachex.set(@key, feature.id, feature)
    {:reply, :ok, state}
  end

  def handle_call({:remove, feature}, _from, state) do
    Cachex.del(@key, feature.id)
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    Cachex.clear(@key)
    {:reply, :ok, state}
  end
end
