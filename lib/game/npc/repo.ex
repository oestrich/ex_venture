defmodule Game.NPC.Repo do
  @moduledoc """
  Repo helper for the NPC modules
  """

  import Ecto.Query

  alias Data.NPCSpawner
  alias Data.Repo

  @doc """
  Get an NPC
  """
  @spec get(integer) :: [Room.t()]
  def get(id) do
    NPCSpawner
    |> Repo.get(id)
    |> Repo.preload(npc: [:npc_items])
  end

  @doc """
  Load all rooms in a zone
  """
  @spec for_zone(Zone.t()) :: [integer()]
  def for_zone(zone) do
    NPCSpawner
    |> where([ns], ns.zone_id == ^zone.id)
    |> select([ns], ns.id)
    |> Repo.all()
  end

  @doc """
  Read through cache for the global resources
  """
  def get_name(id) do
    case NPC |> Repo.get(id) do
      nil ->
        {:error, :unknown}

      npc ->
        {:ok, Map.take(npc, [:id, :name])}
    end
  end
end
