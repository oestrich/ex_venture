defmodule Web.Class do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Class
  alias Data.Repo
  alias Data.Skill
  alias Data.Stats

  @doc """
  Get all classes
  """
  @spec all() :: [Class.t]
  def all() do
    Class
    |> order_by([c], c.id)
    |> Repo.all
  end

  @doc """
  Get a class

  Preload skills
  """
  @spec get(id :: integer) :: [Class.t]
  def get(id) do
    Class
    |> where([c], c.id == ^id)
    |> preload([:skills])
    |> preload([skills: ^(from s in Skill, order_by: [s.level, s.id])])
    |> Repo.one
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %Class{} |> Class.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(class :: Class.t) :: changeset :: map
  def edit(class), do: class |> Class.changeset(%{})

  @doc """
  Create a class
  """
  @spec create(params :: map) :: {:ok, Class.t} | {:error, changeset :: map}
  def create(params) do
    %Class{}
    |> Class.changeset(cast_params(params))
    |> Repo.insert()
  end

  @doc """
  Update an zone
  """
  @spec update(id :: integer, params :: map) :: {:ok, Zone.t} | {:error, changeset :: map}
  def update(id, params) do
    id
    |> get()
    |> Class.changeset(cast_params(params))
    |> Repo.update
  end

  @doc """
  Cast params into what `Data.Class` expects
  """
  @spec cast_params(params :: map) :: map
  def cast_params(params) do
    params
    |> parse_stats()
  end

  defp parse_stats(params = %{"each_level_stats" => stats}) do
    case Poison.decode(stats) do
      {:ok, stats} -> stats |> cast_stats(params)
      _ -> params
    end
  end
  defp parse_stats(params), do: params

  defp cast_stats(stats, params) do
    case stats |> Stats.load do
      {:ok, stats} ->
        Map.put(params, "each_level_stats", stats)
        _ -> params
    end
  end
end
