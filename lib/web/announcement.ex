defmodule Web.Announcement do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Announcement
  alias Data.Repo
  alias Web.Pagination

  @doc """
  Get all bugs
  """
  @spec all(Keyword.t()) :: [Announcement.t()]
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})

    Announcement
    |> order_by([a], desc: a.id)
    |> Pagination.paginate(opts)
  end

  @doc """
  Get recent announcements, the most recent 5
  """
  def sticky() do
    Announcement
    |> order_by([a], desc: a.published_at)
    |> where([a], a.is_sticky)
    |> Repo.all()
  end

  @doc """
  Get recent announcements, the most recent 5
  """
  def recent() do
    recent =
      Announcement
      |> order_by([a], desc: a.published_at)
      |> where([a], a.is_published and not a.is_sticky)
      |> limit(5)
      |> Repo.all()

    sticky() ++ recent
  end

  @doc """
  Get an announcement
  """
  @spec get(integer()) :: [Announcement.t()]
  def get(id) do
    Announcement
    |> where([b], b.id == ^id)
    |> Repo.one()
  end

  @doc """
  Get an announcement by uuid
  """
  def get_by_uuid(uuid) do
    case Ecto.UUID.cast(uuid) do
      {:ok, uuid} ->
        Announcement
        |> where([b], b.uuid == ^uuid)
        |> Repo.one()

      _ ->
        nil
    end
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: %Announcement{} |> Announcement.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(announcement :: Announcement.t()) :: changeset :: map
  def edit(announcement), do: announcement |> Announcement.changeset(%{})

  @doc """
  Create a announcement
  """
  @spec create(map) :: {:ok, Announcement.t()} | {:error, changeset :: map}
  def create(params) do
    %Announcement{}
    |> Announcement.changeset(cast_params(params))
    |> Repo.insert()
  end

  @doc """
  Update a announcement
  """
  @spec update(id :: integer, params :: map) ::
          {:ok, Announcement.t()} | {:error, changeset :: map}
  def update(id, params) do
    id
    |> get()
    |> Announcement.changeset(cast_params(params))
    |> Repo.update()
  end

  @doc """
  Cast params into what `Data.Item` expects
  """
  @spec cast_params(params :: map) :: map
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
