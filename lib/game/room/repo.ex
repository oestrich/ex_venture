defmodule Game.Room.Repo do
  @moduledoc """
  Repo helper for the Room modules
  """

  import Ecto.Query

  alias Data.Exit
  alias Data.Room
  alias Data.Repo
  alias Game.Item

  @doc """
  Load all rooms
  """
  @spec all() :: [Room.t]
  def all() do
    Room
    |> preload([:room_items, :shops])
    |> Repo.all
  end

  @doc """
  Get a room
  """
  @spec get(id :: integer) :: [Room.t]
  def get(id) do
    Room
    |> Repo.get(id)
    |> Exit.load_exits()
    |> Repo.preload([:room_items, :shops])
  end

  @doc """
  Load all rooms in a zone
  """
  @spec for_zone(zone_id :: integer) :: [Room.t]
  def for_zone(zone_id) do
    Room
    |> where([r], r.zone_id == ^zone_id)
    |> preload([:room_items, :shops])
    |> Repo.all
    |> Enum.map(&migrate_items/1)
    |> Enum.map(&Exit.load_exits/1)
  end

  def update(room, params) do
    room
    |> Room.changeset(params)
    |> Repo.update
  end

  @doc """
  Migrate items after load

  - Ensure usable items have an amount, checks item state
  """
  @spec migrate_items(Room.t()) :: Room.t()
  def migrate_items(room) do
    items = room.items |> Enum.map(&Item.migrate_instance/1)
    %{room | items: items}
  end
end
