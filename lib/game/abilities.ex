defmodule Game.Abilities do
  @moduledoc """
  GenServer to keep track of abilities in the game.

  Stores them in an ETS table
  """

  use GenServer

  alias Data.Ability
  alias Data.Repo

  @key :abilities

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Get an ability
  """
  def get(ability = %Ability{}) do
    get(ability.id)
  end

  def get(id) when is_integer(id) do
    case Cachex.get(@key, id) do
      {:ok, ability} when ability != nil ->
        {:ok, ability}

      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Get all abilities from the cache
  """
  def all() do
    case Cachex.keys(@key) do
      {:ok, keys} ->
        keys
        |> Enum.filter(&is_integer/1)
        |> abilities()

      _ ->
        []
    end
  end

  @doc """
  Get a list of abilities by id
  """
  def abilities(ids) do
    ids
    |> Enum.map(&get/1)
    |> Enum.reject(&(&1 == {:error, :not_found}))
    |> Enum.map(&(elem(&1, 1)))
  end

  @doc """
  Insert a new ability into the loaded data
  """
  def insert(ability) do
    members = :pg2.get_members(@key)

    Enum.map(members, fn member ->
      GenServer.call(member, {:insert, ability})
    end)
  end

  @doc """
  Trigger an ability reload
  """
  def reload(ability), do: insert(ability)

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

    {:ok, %{}, {:continue, :load_abilities}}
  end

  def handle_continue(:load_abilities, state) do
    abilities = Repo.all(Ability)

    Enum.each(abilities, fn ability ->
      Cachex.put(@key, ability.id, ability)
    end)

    {:noreply, state}
  end

  def handle_call({:insert, ability}, _from, state) do
    Cachex.put(@key, ability.id, ability)
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    Cachex.clear(@key)

    {:reply, :ok, state}
  end
end
