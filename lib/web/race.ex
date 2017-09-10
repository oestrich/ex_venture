defmodule Web.Race do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Race
  alias Data.Repo
  alias Data.Stats

  @doc """
  Get all classes
  """
  @spec all() :: [Race.t]
  def all() do
    Race
    |> order_by([r], r.id)
    |> Repo.all
  end

  @doc """
  Get a class

  Preload skills
  """
  @spec get(id :: integer) :: [Race.t]
  def get(id) do
    Race
    |> where([c], c.id == ^id)
    |> Repo.one
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %Race{} |> Race.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(race :: Race.t) :: changeset :: map
  def edit(race), do: race |> Race.changeset(%{})

  @doc """
  Create a race
  """
  @spec create(params :: map) :: {:ok, Race.t} | {:error, changeset :: map}
  def create(params) do
    %Race{}
    |> Race.changeset(cast_params(params))
    |> Repo.insert()
  end

  @doc """
  Update a race
  """
  @spec update(id :: integer, params :: map) :: {:ok, Race.t} | {:error, changeset :: map}
  def update(id, params) do
    id
    |> get()
    |> Race.changeset(cast_params(params))
    |> Repo.update
  end

  @doc """
  Cast params into what `Data.Race` expects
  """
  @spec cast_params(params :: map) :: map
  def cast_params(params) do
    params
    |> parse_stats()
  end

  defp parse_stats(params = %{"starting_stats" => stats}) do
    case Poison.decode(stats) do
      {:ok, stats} -> stats |> cast_stats(params)
      _ -> params
    end
  end
  defp parse_stats(params), do: params

  defp cast_stats(stats, params) do
    case stats |> Stats.load do
      {:ok, stats} ->
        Map.put(params, "starting_stats", stats)
        _ -> params
    end
  end
end
