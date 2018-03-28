defmodule Web.DamageType do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.DamageType
  alias Data.Repo

  @doc """
  Get all bugs
  """
  @spec all() :: [DamageType.t()]
  def all() do
    DamageType
    |> order_by([dt], asc: dt.key)
    |> Repo.all()
  end

  @doc """
  Get a bug
  """
  @spec get(integer()) :: [DamageType.t()]
  def get(id) do
    DamageType
    |> where([b], b.id == ^id)
    |> Repo.one()
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %DamageType{} |> DamageType.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(damage_type :: DamageType.t()) :: changeset :: map
  def edit(damage_type), do: damage_type |> DamageType.changeset(%{})

  @doc """
  Create a damage_type
  """
  @spec create(params :: map) :: {:ok, DamageType.t()} | {:error, changeset :: map}
  def create(params) do
    changeset = %DamageType{} |> DamageType.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, damage_type} ->
        {:ok, damage_type}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Update an damage_type
  """
  @spec update(id :: integer, params :: map) :: {:ok, DamageType.t()} | {:error, changeset :: map}
  def update(id, params) do
    damage_type = id |> get()
    changeset = damage_type |> DamageType.changeset(params)

    case changeset |> Repo.update() do
      {:ok, damage_type} ->
        {:ok, damage_type}

      anything ->
        anything
    end
  end
end
