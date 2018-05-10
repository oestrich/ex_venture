defmodule Game.DamageTypes do
  @moduledoc """
  GenServer to keep track of damage_types in the game.

  Stores them in an ETS table
  """

  use GenServer

  alias Data.DamageType
  alias Data.Repo

  @key :damage_types

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec get(integer() | String.t()) :: DamageType.t() | nil
  def get(key) when is_binary(key) do
    case Cachex.get(@key, key) do
      {:ok, damage_type} when damage_type != nil ->
        {:ok, damage_type}

      _ ->
        create_default_damage_type(key)
    end
  end

  defp create_default_damage_type(key) do
    changeset =
      %DamageType{}
      |> DamageType.changeset(%{
        key: key,
        stat_modifier: "strength",
        reverse_stat: "strength"
      })

    case changeset |> Repo.insert() do
      {:ok, damage_type} ->
        Cachex.set(@key, damage_type.key, damage_type)
        {:ok, damage_type}

      {:error, _changeset} ->
        raise "Error creating the damage type dynamically"
    end
  end

  @spec damage_types([integer()]) :: [DamageType.t()]
  def damage_types(ids) do
    ids
    |> Enum.map(&get/1)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Insert a new damage_type into the loaded data
  """
  @spec insert(DamageType.t()) :: :ok
  def insert(damage_type) do
    members = :pg2.get_members(@key)

    Enum.map(members, fn member ->
      GenServer.call(member, {:insert, damage_type})
    end)
  end

  @doc """
  Trigger an damage_type reload
  """
  @spec reload(DamageType.t()) :: :ok
  def reload(damage_type), do: insert(damage_type)

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

    GenServer.cast(self(), :load_damage_types)

    {:ok, %{}}
  end

  def handle_cast(:load_damage_types, state) do
    damage_types = DamageType |> Repo.all()

    Enum.each(damage_types, fn damage_type ->
      Cachex.set(@key, damage_type.key, damage_type)
    end)

    {:noreply, state}
  end

  def handle_call({:insert, damage_type}, _from, state) do
    Cachex.set(@key, damage_type.key, damage_type)

    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    Cachex.clear(:damage_types)

    {:reply, :ok, state}
  end
end
