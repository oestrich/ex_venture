defmodule Web.NPC do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.NPC
  alias Data.NPCSpawner
  alias Data.Stats
  alias Data.Repo

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
    |> preload([npc_spawners: [:zone, :room]])
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
    changeset = id |> get() |> NPC.changeset(cast_params(params))
    case changeset |> Repo.update do
      {:ok, npc} ->
        npc = npc |> Repo.preload([npc_spawners: [:npc]])
        Enum.map(npc.npc_spawners, fn (npc_spawner) ->
          Game.NPC.update(npc_spawner.id, npc_spawner)
        end)
        {:ok, npc}
      anything -> anything
    end
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
  Load a npc spawner
  """
  @spec get_spawner(id :: integer) :: NPCSpawner.t
  def get_spawner(npc_spawner_id) do
    NPCSpawner
    |> Repo.get(npc_spawner_id)
    |> Repo.preload([:npc])
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new_spawner(npc :: NPC.t) :: changeset :: map
  def new_spawner(npc) do
    npc
    |> Ecto.build_assoc(:npc_spawners)
    |> NPCSpawner.changeset(%{})
  end

  @doc """
  Get a changeset for an edit page
  """
  @spec edit_spawner(npc_spawner :: NPCSpawner.t) :: changeset :: map
  def edit_spawner(npc_spawner), do: npc_spawner |> NPCSpawner.changeset(%{})

  @doc """
  Add a new NPC spawner
  """
  def add_spawner(npc_id, params) do
    changeset = npc_id |> Ecto.build_assoc(:npc_spawners) |> NPCSpawner.changeset(params)
    case changeset |> Repo.insert() do
      {:ok, npc_spawner} ->
        npc_spawner = npc_spawner |> Repo.preload([:npc])
        Game.Zone.spawn_npc(npc_spawner.zone_id, npc_spawner)
        {:ok, npc_spawner}
      anything -> anything
    end
  end

  @doc """
  Update a NPC Spawner
  """
  @spec update_spawner(id :: integer, params :: map) :: {:ok, NPCSpawner.t} | {:error, changeset :: map}
  def update_spawner(id, params) do
    changeset = id |> get_spawner() |> NPCSpawner.update_changeset(params)
    case changeset |> Repo.update do
      {:ok, npc_spawner} ->
        npc_spawner = npc_spawner |> Repo.preload([:npc])
        Game.NPC.update(npc_spawner.id, npc_spawner)
        {:ok, npc_spawner}
      anything -> anything
    end
  end

  @doc """
  Delete a room exit
  """
  @spec delete_spawner(npc_spawner_id :: integer) :: {:ok, NPCSpawner.t} | {:error, changeset :: map}
  def delete_spawner(npc_spawner_id) do
    npc_spawner = npc_spawner_id |> get_spawner()
    case npc_spawner |> Repo.delete() do
      {:ok, npc_spawner} ->
        Game.NPC.terminate(npc_spawner.id)
        {:ok, npc_spawner}
      anything -> anything
    end
  end
end
