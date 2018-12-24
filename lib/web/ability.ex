defmodule Web.Ability do
  @moduledoc """
  Context Module for talking to the in game abilities
  """

  import Ecto.Query

  alias Data.Ability
  alias Data.Repo

  @doc """
  Get all abilities active in the game
  """
  def all() do
    Ability
    |> order_by([c], c.name)
    |> Repo.all()
  end

  @doc """
  Get a ability
  """
  def get(id) do
    case Repo.get(Ability, id) do
      nil ->
        {:error, :not_found}

      ability ->
        {:ok, ability}
    end
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: map()
  def new(), do: %Ability{} |> Ability.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(Ability.t()) :: map()
  def edit(ability), do: ability |> Ability.changeset(%{})

  @doc """
  Create an ability
  """
  @spec create(map) :: {:ok, Ability.t()} | {:error, map}
  def create(params) do
    changeset = %Ability{} |> Ability.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, ability} ->
        {:ok, ability}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Update an ability
  """
  @spec update(Ability.t(), map()) :: {:ok, Ability.t()} | {:error, map}
  def update(ability, params) do
    changeset = ability |> Ability.changeset(params)

    case changeset |> Repo.update() do
      {:ok, ability} ->
        {:ok, ability}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
