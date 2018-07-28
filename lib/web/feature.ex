defmodule Web.Feature do
  @moduledoc """
  Context for Features
  """

  import Ecto.Query

  alias Data.Feature
  alias Data.Repo
  alias Game.Features
  alias Web.Pagination

  @doc """
  Get all features
  """
  @spec all(Keyword.t()) :: [Feature.t()]
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})

    Feature
    |> order_by([f], asc: f.key)
    |> Pagination.paginate(opts)
  end

  @doc """
  Get a single feature
  """
  @spec get(integer()) :: Feature.t()
  def get(id) do
    Feature
    |> Repo.get(id)
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: %Feature{} |> Feature.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(Feature.t()) :: Ecto.Changeset.t()
  def edit(feature), do: feature |> Feature.changeset(%{})

  @doc """
  Create an feature
  """
  @spec create(map()) :: {:ok, Feature.t()} | {:error, Ecto.Changeset.t()}
  def create(params) do
    changeset = %Feature{} |> Feature.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, feature} ->
        Features.insert(feature)
        {:ok, feature}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Update an feature
  """
  @spec update(integer(), map()) :: {:ok, Feature.t()} | {:error, Ecto.Changeset.t()}
  def update(id, params) do
    feature = id |> get()
    changeset = feature |> Feature.changeset(params)

    case changeset |> Repo.update() do
      {:ok, feature} ->
        Features.reload(feature)
        {:ok, feature}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Delete a feature
  """
  @spec delete(integer()) :: {:ok, Feature.t()}
  def delete(id) do
    id
    |> get()
    |> Repo.delete()
  end
end
