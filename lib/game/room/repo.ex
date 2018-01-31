defmodule Game.Room.Repo do
  @moduledoc """
  Repo helper for the Room modules
  """

  import Ecto.Query

  alias Data.Exit
  alias Data.Room
  alias Data.Repo

  @doc """
  Load all rooms
  """
  @spec all() :: [Room.t()]
  def all() do
    Room
    |> preload([:room_items, :shops])
    |> Repo.all()
  end

  @doc """
  Get a room
  """
  @spec get(integer) :: [Room.t()]
  def get(id) do
    Room
    |> Repo.get(id)
    |> Exit.load_exits()
    |> Repo.preload([:room_items, :shops])
  end

  @doc """
  Load all rooms in a zone
  """
  @spec for_zone(integer()) :: [integer()]
  def for_zone(zone_id) do
    Room
    |> where([r], r.zone_id == ^zone_id)
    |> select([r], r.id)
    |> Repo.all()
  end

  def update(room, params) do
    room
    |> Room.changeset(params)
    |> Repo.update()
  end
end
