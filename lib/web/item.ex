defmodule Web.Item do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  alias Data.Item
  alias Data.Stats
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
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %Item{} |> Item.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(item :: Item.t) :: changeset :: map
  def edit(item), do: item |> Item.changeset(%{})

  @doc """
  Create an item
  """
  @spec create(params :: map) :: {:ok, Item.t} | {:error, changeset :: map}
  def create(params) do
    changeset = %Item{} |> Item.changeset(cast_params(params))
    case changeset |> Repo.insert() do
      {:ok, item} ->
        Items.insert(item)
        {:ok, item}
      anything -> anything
    end
  end

  @doc """
  Update an item
  """
  @spec update(id :: integer, params :: map) :: {:ok, Item.t} | {:error, changeset :: map}
  def update(id, params) do
    item = id |> get()
    changeset = item |> Item.changeset(cast_params(params))
    case changeset |> Repo.update do
      {:ok, item} ->
        Items.reload(item)
        {:ok, item}
      anything -> anything
    end
  end

  def cast_params(params) do
    params
    |> split_keywords()
    |> parse_stats()
    |> Map.put("effects", [])
  end

  # Split keywords into an array of strings based on a comma
  defp split_keywords(params = %{"keywords" => keywords}) do
    params |> Map.put("keywords", keywords |> String.split(",") |> Enum.map(&String.trim/1))
  end
  defp split_keywords(params), do: params

  defp parse_stats(params = %{"stats" => stats}) do
    case Poison.decode(stats) do
      {:ok, stats} -> stats |> cast_stats(params)
      _ -> params
    end
  end
  defp parse_stats(params), do: params

  defp cast_stats(stats, params) do
    case stats |> Stats.load do
      {:ok, stats} ->
        Map.put(params, "stats", stats)
        _ -> params
    end
  end
end
