defmodule Web.ItemTag do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.ItemTag
  alias Data.Repo
  alias Game.Items
  alias Web.Item

  @doc """
  Load all items
  """
  @spec all() :: [ItemTag.t]
  def all() do
    ItemTag
    |> order_by([i], i.id)
    |> Repo.all
  end

  @doc """
  Get a single item
  """
  @spec get(id :: integer) :: ItemTag.t
  def get(id) do
    ItemTag |> Repo.get(id)
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %ItemTag{} |> ItemTag.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(item :: ItemTag.t) :: changeset :: map
  def edit(item), do: item |> ItemTag.changeset(%{})

  @doc """
  Create an item module
  """
  @spec create(params :: map) :: {:ok, ItemTag.t} | {:error, changeset :: map}
  def create(params) do
    %ItemTag{}
    |> ItemTag.changeset(Item.cast_params(params))
    |> Repo.insert()
  end

  @doc """
  Update an item
  """
  @spec update(id :: integer, params :: map) :: {:ok, ItemTag.t} | {:error, changeset :: map}
  def update(id, params) do
    item_tag = id |> get()
    changeset = item_tag |> ItemTag.changeset(Item.cast_params(params))
    case changeset |> Repo.update do
      {:ok, item_tag} ->
        item_tag
        |> Repo.preload([:items])
        |> Map.get(:items)
        |> Enum.each(&Items.reload/1)

        {:ok, item_tag}
      error -> error
    end
  end
end
