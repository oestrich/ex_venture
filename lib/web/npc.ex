defmodule Web.NPC do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.NPC
  alias Data.Stats
  alias Data.Repo
  alias Data.ZoneNPC

  @doc """
  Get all npcs
  """
  @spec all() :: [NPC.t]
  def all() do
    NPC
    |> order_by([n], n.id)
    |> Repo.all
  end

  @doc """
  Get a npc
  """
  @spec get(id :: integer) :: [NPC.t]
  def get(id) do
    NPC
    |> where([c], c.id == ^id)
    |> preload([zone_npcs: [:zone, :room]])
    |> Repo.one
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %NPC{} |> NPC.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(npc :: NPC.t) :: changeset :: map
  def edit(npc), do: npc |> NPC.changeset(%{})

  @doc """
  Create a npc
  """
  @spec create(params :: map) :: {:ok, NPC.t} | {:error, changeset :: map}
  def create(params) do
    %NPC{}
    |> NPC.changeset(cast_params(params))
    |> Repo.insert()
  end

  @doc """
  Update a NPC
  """
  @spec update(id :: integer, params :: map) :: {:ok, NPC.t} | {:error, changeset :: map}
  def update(id, params) do
    id
    |> get()
    |> NPC.changeset(cast_params(params))
    |> Repo.update
  end

  @doc """
  Cast params into what `Data.NPC` expects
  """
  @spec cast_params(params :: map) :: map
  def cast_params(params) do
    params
    |> parse_stats()
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

  #
  # Zone NPC
  #

  @doc """
  Get a changeset for a new page
  """
  @spec new_spawner(npc :: NPC.t) :: changeset :: map
  def new_spawner(npc) do
    npc
    |> Ecto.build_assoc(:zone_npcs)
    |> ZoneNPC.changeset(%{})
  end

  @doc """
  Add a new NPC spawner
  """
  def add_spawner(npc_id, params) do
    npc_id
    |> Ecto.build_assoc(:zone_npcs)
    |> ZoneNPC.changeset(params)
    |> Repo.insert()
  end
end
