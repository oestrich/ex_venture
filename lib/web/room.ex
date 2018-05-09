defmodule Web.Room do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Exit
  alias Data.Item
  alias Data.NPCSpawner
  alias Data.Room
  alias Data.Room.Feature
  alias Data.RoomItem
  alias Data.Repo
  alias Data.Zone
  alias Game.Config
  alias Game.Door
  alias Game.Items
  alias Game.Room.Repo, as: RoomRepo
  alias Web.NPC
  alias Web.Shop

  @doc """
  Get a room

  Preload rooms in each direction and the zone
  """
  @spec get(integer()) :: [Room.t()]
  def get(id) do
    Room
    |> where([r], r.id == ^id)
    |> preload(zone: [:rooms], room_items: [:item], npc_spawners: [:npc], shops: [:shop_items])
    |> Repo.one()
    |> Exit.load_exits(preload: true)
  end

  def get(id, tuple: true) do
    case get(id) do
      nil ->
        {:error, :not_found}

      room ->
        {:ok, room}
    end
  end

  @doc """
  Get npcs for a room
  """
  @spec npcs(room_id :: integer) :: [NPC.t()]
  def npcs(room_id) do
    NPCSpawner
    |> where([n], n.room_id == ^room_id)
    |> preload([:npc])
    |> Repo.all()
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new(zone :: Zone.t(), params :: map) :: changeset :: map
  def new(zone, params) do
    zone
    |> Ecto.build_assoc(:rooms)
    |> Room.changeset(params)
  end

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(room :: Room.t()) :: changeset :: map
  def edit(room), do: room |> Room.changeset(%{})

  @doc """
  Create a room
  """
  @spec create(zone :: Zone.t(), params :: map) :: {:ok, Room.t()} | {:error, changeset :: map}
  def create(zone, params) do
    changeset = zone |> Ecto.build_assoc(:rooms) |> Room.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, room} ->
        room = RoomRepo.get(room.id)
        Game.Zone.spawn_room(zone.id, room)
        {:ok, room}

      anything ->
        anything
    end
  end

  @doc """
  Update a room
  """
  @spec update(id :: integer, params :: map) :: {:ok, Room.t()} | {:error, changeset :: map}
  def update(id, params) do
    room = id |> get()
    changeset = room |> Room.changeset(params)

    case changeset |> Repo.update() do
      {:ok, room} ->
        room = RoomRepo.get(room.id)
        Game.Room.update(room.id, room)
        {:ok, room}

      anything ->
        anything
    end
  end

  @doc """
  Delete a room and everything associated with it
  """
  @spec delete(integer()) :: {:ok, Room.t()}
  def delete(id) do
    with {:ok, room} <- get(id, tuple: true),
         {:ok, room} <- check_graveyard(room),
         {:ok, room} <- check_starting_room(room) do
      room
      |> delete_spawners()
      |> delete_shops()
      |> delete_item_spawners()
      |> delete_room_exits()
      |> terminate_and_destroy_room()
    end
  end

  defp check_graveyard(room) do
    case room.is_graveyard do
      true ->
        {:error, :graveyard, room}

      false ->
        double_check_graveyard(room)
    end
  end

  defp double_check_graveyard(room) do
    count =
      Zone
      |> where([z], z.graveyard_id == ^room.id)
      |> select([z], count(z.id))
      |> Repo.one()

    case count == 0 do
      true ->
        {:ok, room}

      false ->
        {:error, :graveyard, room}
    end
  end

  defp check_starting_room(room) do
    starting_save = Config.starting_save()
    case room.id == starting_save.room_id do
      true ->
        {:error, :starting_room, room}

      false ->
        {:ok, room}
    end
  end

  defp delete_spawners(room) do
    Enum.each(room.npc_spawners, fn npc_spawner ->
      NPC.delete_spawner(npc_spawner.id)
    end)
    room
  end

  defp delete_shops(room) do
    Enum.each(room.shops, fn shop ->
      Shop.delete(shop.id)
    end)
    room
  end

  defp delete_item_spawners(room) do
    Enum.each(room.room_items, fn room_item ->
      delete_item(room_item.id)
    end)
    room
  end

  defp delete_room_exits(room) do
    Enum.each(room.exits, fn room_exit ->
      delete_exit(room_exit.id)
    end)
    room
  end

  defp terminate_and_destroy_room(room) do
    Game.Zone.terminate_room(room)
    Repo.delete(room)
  end

  #
  # Room Items
  #

  @doc """
  Get a changeset for a new room new
  """
  @spec new_item(room :: Room.t()) :: changeset :: map
  def new_item(room) do
    room
    |> Ecto.build_assoc(:room_items)
    |> RoomItem.changeset(%{})
  end

  @doc """
  Add an item to a room
  """
  @spec add_item(room :: Room.t(), item_id :: integer) ::
          {:ok, Room.t()} | {:error, changeset :: map}
  def add_item(room, item_id) when is_binary(item_id) do
    {item_id, _} = Integer.parse(item_id)
    add_item(room, item_id)
  end

  def add_item(room, item_id) do
    item = Items.item(item_id)
    instance = Item.instantiate(item)
    changeset = room |> Room.changeset(%{items: [instance | room.items]})

    case changeset |> Repo.update() do
      {:ok, room} ->
        Game.Room.update(room.id, room)
        {:ok, room}

      anything ->
        anything
    end
  end

  @doc """
  Create a room item
  """
  @spec create_item(room :: Room.t(), params :: map) ::
          {:ok, RoomItem.t()} | {:error, changeset :: map}
  def create_item(room, params) do
    changeset = room |> Ecto.build_assoc(:room_items) |> RoomItem.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, room_item} ->
        room = RoomRepo.get(room_item.room_id)
        Game.Room.update(room.id, room)
        {:ok, room_item}

      anything ->
        anything
    end
  end

  @doc """
  Delete a room item
  """
  @spec delete_item(room_item_id :: integer) :: {:ok, RoomItem.t()}
  def delete_item(room_item_id) do
    room_item = RoomItem |> Repo.get(room_item_id)

    case room_item |> Repo.delete() do
      {:ok, room_item} ->
        room = RoomRepo.get(room_item.room_id)
        Game.Room.update(room.id, room)
        {:ok, room_item}

      anything ->
        anything
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
  @spec create_exit(params :: map) :: {:ok, Exit.t()} | {:error, changeset :: map}
  def create_exit(params) do
    changeset = %Exit{} |> Exit.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, room_exit} ->
        room_exit |> update_directions()
        room_exit |> Door.maybe_load()
        {:ok, room_exit}

      anything ->
        anything
    end
  end

  @doc """
  Delete a room exit
  """
  @spec delete_exit(exit_id :: integer) :: {:ok, Exit.t()} | {:error, changeset :: map}
  def delete_exit(exit_id) do
    room_exit = Exit |> Repo.get(exit_id)

    case room_exit |> Repo.delete() do
      {:ok, room_exit} ->
        room_exit |> update_directions()
        room_exit |> Door.remove()
        {:ok, room_exit}

      anything ->
        anything
    end
  end

  defp update_directions(room_exit) do
    [:north_id, :south_id, :east_id, :west_id, :up_id, :down_id, :in_id, :out_id]
    |> Enum.each(fn direction ->
      case Map.get(room_exit, direction) do
        nil ->
          nil

        id ->
          room = RoomRepo.get(id)
          Game.Room.update(room.id, room)
      end
    end)
  end

  #
  # Features
  #

  @doc """
  Get a room feature
  """
  @spec get_feature(Room.t(), String.t()) :: map()
  def get_feature(room, id) do
    Enum.find(room.features, fn feature ->
      feature.id == id
    end)
  end

  @doc """
  Add a feature to a room
  """
  @spec add_feature(Room.t(), map()) :: {:ok, Room.t()} | {:error, Ecto.Changeset.t()}
  def add_feature(room, feature) do
    {:ok, feature} = Feature.load(feature)
    changeset = room |> Room.feature_changeset(%{features: [feature | room.features]})

    case changeset |> Repo.update() do
      {:ok, room} ->
        Game.Room.update(room.id, room)
        {:ok, room}

      {:error, _} ->
        {:error, Map.put(feature, :id, nil)}
    end
  end

  @doc """
  Edit a room feature from a room
  """
  @spec edit_feature(Room.t(), String.t(), map()) ::
          {:ok, Room.t()} | {:error, Ecto.Changeset.t()}
  def edit_feature(room, feature_id, params) do
    features =
      room.features
      |> Enum.reject(&(&1.id == feature_id))

    {:ok, feature} =
      params
      |> Map.put("id", feature_id)
      |> Feature.load()

    changeset = room |> Room.feature_changeset(%{features: [feature | features]})

    case changeset |> Repo.update() do
      {:ok, room} ->
        Game.Room.update(room.id, room)
        {:ok, room}

      {:error, _} ->
        {:error, feature}
    end
  end

  @doc """
  Delete a room feature from a room
  """
  @spec delete_feature(Room.t(), String.t()) :: {:ok, Room.t()} | {:error, Ecto.Changeset.t()}
  def delete_feature(room, feature_id) do
    features =
      room.features
      |> Enum.reject(&(&1.id == feature_id))

    changeset = room |> Room.feature_changeset(%{features: features})

    case changeset |> Repo.update() do
      {:ok, room} ->
        Game.Room.update(room.id, room)
        {:ok, room}

      anything ->
        anything
    end
  end
end
