defmodule Web.Shop do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Repo
  alias Data.Room
  alias Data.Shop

  alias Game.Room.Repo, as: RoomRepo

  @doc """
  Get a shop
  """
  @spec get(id :: integer) :: [Room.t]
  def get(id) do
    Shop
    |> where([s], s.id == ^id)
    |> Repo.one
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new(room :: Room.t) :: changeset :: map
  def new(room) do
    room
    |> Ecto.build_assoc(:shops)
    |> Shop.changeset(%{})
  end

  @doc """
  Create a shop
  """
  @spec create(room :: Room.t, params :: map) :: {:ok, Shop.t} | {:error, changeset :: map}
  def create(room, params) do
    changeset = room |> Ecto.build_assoc(:shops) |> Shop.changeset(params)
    case changeset |> Repo.insert() do
      {:ok, shop} ->
        room = RoomRepo.get(room.id)
        Game.Room.update(room.id, room)
        {:ok, shop}
      anything -> anything
    end
  end

  @doc """
  Update a shop
  """
  @spec update(id :: integer, params :: map) :: {:ok, Shop.t} | {:error, changeset :: map}
  def update(id, params) do
    changeset = id |> get() |> Shop.changeset(params)
    case changeset |> Repo.update() do
      {:ok, shop} ->
        room = RoomRepo.get(shop.room_id)
        Game.Room.update(room.id, room)
        {:ok, shop}
      anything -> anything
    end
  end
end
