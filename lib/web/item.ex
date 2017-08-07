defmodule Web.Item do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  alias Data.Item
  alias Data.Repo
  alias Game.Items

  @doc """
  Load all items
  """
  @spec all() :: [Item.t]
  def all() do
    Item |> Repo.all
  end

  @doc """
  Get a single item
  """
  @spec get(id :: integer) :: Item.t
  def get(id) do
    Item |> Repo.get(id)
  end

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(item :: Item.t) :: changeset :: map
  def edit(item), do: item |> Item.changeset(%{})

  @doc """
  Update an item
  """
  @spec update(id :: integer, params :: map) :: {:ok, Item.t} | {:error, changeset :: map}
  def update(id, params) do
    item = id |> get()
    changeset = item |> Item.changeset(fix_keywords(params))
    case changeset |> Repo.update do
      {:ok, item} ->
        Items.reload(item)
        {:ok, item}
      anything -> anything
    end
  end

  # Split keywords into an array of strings based on a comma
  defp fix_keywords(params = %{"keywords" => keywords}) do
    params |> Map.put("keywords", keywords |> String.split(",") |> Enum.map(&String.trim/1))
  end
  defp fix_keywords(params), do: params
end
