defmodule Web.Feature do
  @moduledoc """
  Context for Features
  """

  import Ecto.Query

  alias Data.Feature
  alias Data.Repo
  alias Web.Pagination

  @doc """
  Get all features
  """
  @spec all(Keyword.t()) :: [Feature.t()]
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})

    Feature
    |> order_by([f], asc: f.name)
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
    %Feature{}
    |> Feature.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Update an feature
  """
  @spec update(integer(), map()) :: {:ok, Feature.t()} | {:error, Ecto.Changeset.t()}
  def update(id, params) do
    id
    |> get()
    |> Feature.changeset(params)
    |> Repo.update()
  end
end
