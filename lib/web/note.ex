defmodule Web.Note do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Note
  alias Data.Repo
  alias Web.Filter
  alias Web.Pagination

  @behaviour Filter

  @doc """
  Get all notes
  """
  @spec all(Keyword.t()) :: [Note.t()]
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})

    Note
    |> order_by([u], desc: u.updated_at)
    |> Filter.filter(opts[:filter], __MODULE__)
    |> Pagination.paginate(opts)
  end

  @impl Filter
  def filter_on_attribute({"tag", value}, query) do
    query
    |> where([n], fragment("? @> ?::varchar[]", n.tags, [^value]))
  end
  def filter_on_attribute(_, query), do: query

  @doc """
  Get a note
  """
  @spec get(integer()) :: [Note.t]
  def get(id) do
    Note
    |> where([n], n.id == ^id)
    |> Repo.one
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: map()
  def new(), do: %Note{} |> Note.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(Note.t()) :: map()
  def edit(note), do: note |> Note.changeset(%{})

  @doc """
  Create a note
  """
  @spec create(map()) :: {:ok, Note.t} | {:error, map}
  def create(params) do
    %Note{}
    |> Note.changeset(cast_params(params))
    |> Repo.insert()
  end

  @doc """
  Update an zone
  """
  @spec update(integer(), map()) :: {:ok, Zone.t} | {:error, map()}
  def update(id, params) do
    id
    |> get()
    |> Note.changeset(cast_params(params))
    |> Repo.update
  end

  @doc """
  Cast params into what `Data.Note` expects
  """
  @spec cast_params(map) :: map
  def cast_params(params) do
    params
    |> parse_tags()
  end

  def parse_tags(params = %{"tags" => tags}) do
    tags =
      tags
      |> String.split(",")
      |> Enum.map(&String.trim/1)

    params
    |> Map.put("tags", tags)
  end
  def parse_tags(params), do: params
end
