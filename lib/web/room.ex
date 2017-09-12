defmodule Web.Room do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Exit
  alias Data.NPCSpawner
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
    |> preload([zone: [:rooms], room_items: [:item], npc_spawners: [:npc], shops: []])
    |> Repo.one
    |> Exit.load_exits(preload: true)
  end

  @doc """
  Get npcs for a room
  """
  @spec npcs(room_id :: integer) :: [NPC.t]
  def npcs(room_id) do
    NPCSpawner
    |> where([n], n.room_id == ^room_id)
    |> preload([:npc])
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
        room = RoomRepo.get(room.id)
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

  #
  # Room Exits
  #

  @doc """
  Get a changeset for a new room exit
  """
  @spec new_exit() :: changeset :: map
  def new_exit(), do: %Exit{} |> Exit.changeset(%{})

  @doc """
  Create a room exit
  """
  @spec create_exit(params :: map) :: {:ok, Exit.t} | {:error, changeset :: map}
  def create_exit(params) do
    changeset = %Exit{} |> Exit.changeset(params)
    case changeset |> Repo.insert() do
      {:ok, room_exit} ->
        room_exit |> update_directions()
        {:ok, room_exit}
      anything -> anything
    end
  end

  @doc """
  Delete a room exit
  """
  @spec delete_exit(exit_id :: integer) :: {:ok, Exit.t} | {:error, changeset :: map}
  def delete_exit(exit_id) do
    room_exit = Exit |> Repo.get(exit_id)
    case room_exit |> Repo.delete() do
      {:ok, room_exit} ->
        room_exit |> update_directions()
        {:ok, room_exit}
      anything -> anything
    end
  end

  defp update_directions(room_exit) do
    [:north_id, :south_id, :east_id, :west_id]
    |> Enum.each(fn (direction) ->
      case Map.get(room_exit, direction) do
        nil -> nil
        id ->
          room = RoomRepo.get(id)
          Game.Room.update(room.id, room)
      end
    end)
  end
end
