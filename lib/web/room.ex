defmodule Web.Room do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.NPC
  alias Data.Room
  alias Data.RoomItem
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
    |> preload([zone: [:rooms], room_items: [:item]])
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

  #
  # Room Items
  #

  @doc """
  Get a changeset for a new room new
  """
  @spec new_item(room :: Room.t) :: changeset :: map
  def new_item(room) do
    room
    |> Ecto.build_assoc(:room_items)
    |> RoomItem.changeset(%{})
  end

  @doc """
  Add an item to a room
  """
  @spec add_item(room :: Room.t, item_id :: integer) :: {:ok, Room.t} | {:error, changeset :: map}
  def add_item(room, item_id) do
    changeset = room |> Room.changeset(%{item_ids: [item_id | room.item_ids]})
    case changeset |> Repo.update() do
      {:ok, room} ->
        Game.Room.update(room.id, room)
        {:ok, room}
      anything -> anything
    end
  end

  @doc """
  Create a room item
  """
  @spec create_item(room :: Room.t, params :: map) :: {:ok, RoomItem.t} | {:error, changeset :: map}
  def create_item(room, params) do
    changeset = room |> Ecto.build_assoc(:room_items) |> RoomItem.changeset(params)
    case changeset |> Repo.insert() do
      {:ok, room_item} ->
        room = RoomRepo.get(room_item.room_id)
        Game.Room.update(room.id, room)
        {:ok, room_item}
      anything -> anything
    end
  end

  @doc """
  Delete a room item
  """
  @spec delete_item(room_item_id :: integer) :: {:ok, RoomItem.t}
  def delete_item(room_item_id) do
    room_item = RoomItem |> Repo.get(room_item_id)
    case room_item |> Repo.delete do
      {:ok, room_item} ->
        room = RoomRepo.get(room_item.room_id)
        Game.Room.update(room.id, room)
        {:ok, room_item}
      anything -> anything
    end
  end
end
