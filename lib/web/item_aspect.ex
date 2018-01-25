defmodule Web.ItemAspect do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.ItemAspect
  alias Data.Repo
  alias Game.Items
  alias Web.Item

  @doc """
  Load all items
  """
  @spec all() :: [ItemAspect.t()]
  def all() do
    ItemAspect
    |> order_by([i], i.id)
    |> Repo.all()
  end

  @doc """
  Get a single item
  """
  @spec get(id :: integer) :: ItemAspect.t()
  def get(id) do
    ItemAspect |> Repo.get(id)
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %ItemAspect{} |> ItemAspect.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(item :: ItemAspect.t()) :: changeset :: map
  def edit(item), do: item |> ItemAspect.changeset(%{})

  @doc """
  Create an item module
  """
  @spec create(params :: map) :: {:ok, ItemAspect.t()} | {:error, changeset :: map}
  def create(params) do
    %ItemAspect{}
    |> ItemAspect.changeset(Item.cast_params(params))
    |> Repo.insert()
  end

  @doc """
  Update an item
  """
  @spec update(id :: integer, params :: map) :: {:ok, ItemAspect.t()} | {:error, changeset :: map}
  def update(id, params) do
    item_aspect = id |> get()
    changeset = item_aspect |> ItemAspect.changeset(Item.cast_params(params))

    case changeset |> Repo.update() do
      {:ok, item_aspect} ->
        item_aspect
        |> Repo.preload([:items])
        |> Map.get(:items)
        |> Enum.each(&Items.reload/1)

        {:ok, item_aspect}

      error ->
        error
    end
  end
end
