defmodule Game.Proficiencies do
  @moduledoc """
  GenServer to keep track of proficiencies in the game.

  Stores them in an ETS table
  """

  use GenServer

  alias Data.Proficiency
  alias Data.Repo

  @key :proficiencies

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Get an proficiency
  """
  def get(proficiency = %Proficiency{}) do
    get(proficiency.id)
  end

  def get(requirement = %Proficiency.Requirement{}) do
    case get(requirement.id) do
      {:ok, proficiency} ->
        {:ok, Map.put(requirement, :name, proficiency.name)}

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  def get(id) when is_integer(id) do
    case Cachex.get(@key, id) do
      {:ok, proficiency} when proficiency != nil ->
        {:ok, proficiency}

      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Get all proficiencies from the cache
  """
  def all() do
    case Cachex.keys(@key) do
      {:ok, keys} ->
        keys
        |> Enum.filter(&is_integer/1)
        |> proficiencies()

      _ ->
        []
    end
  end

  @doc """
  Get a list of proficiencies by id
  """
  def proficiencies(ids) do
    ids
    |> Enum.map(&get/1)
    |> Enum.reject(&(&1 == {:error, :not_found}))
    |> Enum.map(&(elem(&1, 1)))
  end

  @doc """
  Insert a new proficiency into the loaded data
  """
  def insert(proficiency) do
    members = :pg2.get_members(@key)

    Enum.map(members, fn member ->
      GenServer.call(member, {:insert, proficiency})
    end)
  end

  @doc """
  Trigger an proficiency reload
  """
  def reload(proficiency), do: insert(proficiency)

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

    {:ok, %{}, {:continue, :load_proficiencies}}
  end

  def handle_continue(:load_proficiencies, state) do
    proficiencies = Repo.all(Proficiency)

    Enum.each(proficiencies, fn proficiency ->
      Cachex.put(@key, proficiency.id, proficiency)
    end)

    {:noreply, state}
  end

  def handle_call({:insert, proficiency}, _from, state) do
    Cachex.put(@key, proficiency.id, proficiency)
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    Cachex.clear(@key)

    {:reply, :ok, state}
  end
end
