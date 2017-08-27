defmodule Web.Room do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.NPC
  alias Data.Room
  alias Data.Repo

  @doc """
  Get a room

  Preload rooms in each direction and the zone
  """
  @spec get(id :: integer) :: [Room.t]
  def get(id) do
    Room
    |> where([r], r.id == ^id)
    |> preload([:zone, :north, :east, :south, :west])
    |> Repo.one
  end

  @doc """
  Get npcs for a room
  """
  @spec npcs(room_id :: integer) :: [NPC.t]
  def npcs(room_id) do
    NPC
    |> where([n], n.room_id == ^room_id)
    |> Repo.all
  end
end
