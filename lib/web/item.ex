defmodule Web.Item do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query
  import Web.KeywordsHelper

  alias Data.Effect
  alias Data.Item
  alias Data.Stats
  alias Data.Repo
  alias Game.Items

  @doc """
  Load all items
  """
  @spec all() :: [Item.t]
  def all() do
    Item
    |> order_by([i], i.id)
    |> Repo.all
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

  @doc """
  Cast params into what `Data.Item` expects
  """
  @spec cast_params(params :: map) :: map
  def cast_params(params) do
    params
    |> split_keywords()
    |> parse_stats()
    |> parse_effects()
  end

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

  defp parse_effects(params = %{"effects" => effects}) do
    case Poison.decode(effects) do
      {:ok, effects} -> effects |> cast_effects(params)
      _ -> params
    end
  end
  defp parse_effects(params), do: params

  defp cast_effects(effects, params) do
    effects = effects
    |> Enum.map(fn (effect) ->
      case Effect.load(effect) do
        {:ok, effect} -> effect
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)

    Map.put(params, "effects", effects)
  end
end
