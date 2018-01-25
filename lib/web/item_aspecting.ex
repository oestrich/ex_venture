defmodule Web.ItemAspecting do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  alias Data.Item
  alias Data.ItemAspecting
  alias Data.Repo
  alias Game.Items

  @doc """
  Get a single item
  """
  @spec get(id :: integer) :: ItemAspecting.t()
  def get(id) do
    ItemAspecting
    |> Repo.get(id)
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new(item :: Item.t()) :: changeset :: map
  def new(item), do: item |> Ecto.build_assoc(:item_aspectings) |> ItemAspecting.changeset(%{})

  @doc """
  Create an item aspecting
  """
  @spec create(item :: Item.t(), params :: map) ::
          {:ok, ItemAspecting.t()} | {:error, changeset :: map}
  def create(item, params) do
    changeset =
      item
      |> Ecto.build_assoc(:item_aspectings)
      |> ItemAspecting.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, item_aspecting} ->
        Item
        |> Repo.get(item_aspecting.item_id)
        |> Items.reload()

        {:ok, item_aspecting}

      error ->
        error
    end
  end

  @doc """
  Delete an item aspecting
  """
  def delete(item_aspecting) do
    case item_aspecting |> Repo.delete() do
      {:ok, item_aspecting} ->
        Item
        |> Repo.get(item_aspecting.item_id)
        |> Items.reload()

        {:ok, item_aspecting}

      error ->
        error
    end
  end
end
