defmodule Web.Proficiency do
  @moduledoc """
  Context Module for talking to the in game proficiencies
  """

  import Ecto.Query

  alias Data.Proficiency
  alias Data.Repo
  alias Game.Proficiencies

  @doc """
  Get all proficiencies active in the game
  """
  def all() do
    Proficiency
    |> order_by([c], c.name)
    |> Repo.all()
  end

  @doc """
  Get a proficiency
  """
  def get(id) do
    case Repo.get(Proficiency, id) do
      nil ->
        {:error, :not_found}

      proficiency ->
        {:ok, proficiency}
    end
  end

  @doc """
  Get a changeset for a new page
  """
  def new(), do: %Proficiency{} |> Proficiency.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  def edit(proficiency), do: proficiency |> Proficiency.changeset(%{})

  @doc """
  Create an proficiency
  """
  def create(params) do
    changeset = %Proficiency{} |> Proficiency.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, proficiency} ->
        Proficiencies.insert(proficiency)
        {:ok, proficiency}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Update an proficiency
  """
  def update(proficiency, params) do
    changeset = proficiency |> Proficiency.changeset(params)

    case changeset |> Repo.update() do
      {:ok, proficiency} ->
        Proficiencies.reload(proficiency)
        {:ok, proficiency}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
