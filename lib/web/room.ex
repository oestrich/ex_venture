defmodule Web.Room do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.NPC
  alias Data.Room
  alias Data.Repo
  alias Data.Zone

  alias Game.Room.Repo, as: RoomRepo

  @doc """
  Get a room

  Preload rooms in each direction and the zone
  """
  @spec get(id :: integer) :: [Room.t]
  def get(id) do
    Room
    |> where([r], r.id == ^id)
    |> preload([zone: [:rooms]])
    |> preload([:north, :east, :south, :west])
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

  @doc """
  Get a changeset for a new page
  """
  @spec new(zone :: Zone.t) :: changeset :: map
  def new(zone) do
    zone
    |> Ecto.build_assoc(:rooms)
    |> Room.changeset(%{})
  end

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(room :: Room.t) :: changeset :: map
  def edit(room), do: room |> Room.changeset(%{})

  @doc """
  Create a room
  """
  @spec create(zone :: Zone.t, params :: map) :: {:ok, Room.t} | {:error, changeset :: map}
  def create(zone, params) do
    changeset = zone |> Ecto.build_assoc(:rooms) |> Room.changeset(params)
    case changeset |> Repo.insert() do
      {:ok, room} ->
        Game.Zone.spawn_room(zone.id, room)
        {:ok, room}
      anything -> anything
    end
  end

  @doc """
  Update a room
  """
  @spec update(id :: integer, params :: map) :: {:ok, Room.t} | {:error, changeset :: map}
  def update(id, params) do
    room = id |> get()
    changeset = room |> Room.changeset(params)
    case changeset |> Repo.update do
      {:ok, room} ->
        room = RoomRepo.get(room.id)
        Game.Room.update(room.id, room)
        {:ok, room}
      anything -> anything
    end
  end
end
