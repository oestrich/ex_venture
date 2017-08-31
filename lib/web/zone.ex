defmodule Web.Zone do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Zone
  alias Data.Room
  alias Data.Repo

  alias Game.World

  @doc """
  Get all zones
  """
  @spec all() :: [Zone.t]
  def all() do
    Zone
    |> order_by([z], z.id)
    |> Repo.all
  end

  @doc """
  Get a zone

  Preload rooms
  """
  @spec get(id :: integer) :: [Zone.t]
  def get(id) do
    Zone
    |> where([z], z.id == ^id)
    |> preload([rooms: ^(from r in Room, order_by: r.id)])
    |> Repo.one
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %Zone{} |> Zone.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(zone :: Zone.t) :: changeset :: map
  def edit(zone), do: zone |> Zone.changeset(%{})

  @doc """
  Create a zone
  """
  @spec create(params :: map) :: {:ok, Zone.t} | {:error, changeset :: map}
  def create(params) do
    changeset = %Zone{} |> Zone.changeset(params)
    case changeset |> Repo.insert() do
      {:ok, zone} ->
        World.start_child(zone)
        {:ok, zone}
      anything -> anything
    end
  end

  @doc """
  Update an zone
  """
  @spec update(id :: integer, params :: map) :: {:ok, Zone.t} | {:error, changeset :: map}
  def update(id, params) do
    zone = id |> get()
    changeset = zone |> Zone.changeset(params)
    case changeset |> Repo.update do
      {:ok, zone} ->
        Game.Zone.update(zone.id, zone)
        {:ok, zone}
      anything -> anything
    end
  end

  def room_exits() do
    Zone
    |> order_by([z], z.id)
    |> preload([rooms: ^(from r in Room, order_by: r.id)])
    |> Repo.all
    |> Enum.map(fn (zone) ->
      rooms = Enum.map(zone.rooms, &({"#{&1.id} - #{&1.name}", &1.id}))
      {zone.name, rooms}
    end)
  end
end
