defmodule Game.Room.Repo do
  @moduledoc """
  Repo helper for the Room modules
  """

  import Ecto.Query

  alias Data.Room
  alias Data.Repo

  @doc """
  Load all rooms
  """
  @spec all() :: [Room.t]
  def all() do
    Room
    |> preload([:room_items])
    |> Repo.all
  end

  @doc """
  Get a room
  """
  @spec get(id :: integer) :: [Room.t]
  def get(id) do
    Room
    |> Repo.get(id)
    |> Repo.preload([:room_items])
  end

  @doc """
  Load all rooms in a zone
  """
  @spec for_zone(zone_id :: integer) :: [Room.t]
  def for_zone(zone_id) do
    Room
    |> where([r], r.zone_id == ^zone_id)
    |> preload([:room_items])
    |> Repo.all
  end

  def update(room, params) do
    room
    |> Room.changeset(params)
    |> Repo.update
  end
end
