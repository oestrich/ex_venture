defmodule ExVenture.Rooms.Room do
  @moduledoc """
  Schema for Rooms
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias ExVenture.Zones.Zone

  schema "rooms" do
    field(:live_at, :utc_datetime)

    field(:name, :string)
    field(:description, :string)
    field(:listen, :string)

    field(:map_color, :string)
    field(:map_icon, :string)

    field(:x, :integer)
    field(:y, :integer)
    field(:z, :integer)

    field(:notes, :string)

    belongs_to(:zone, Zone)

    # emebeds features

    timestamps()
  end

  def create_changeset(struct, params) do
    struct
    |> cast(params, [:name, :description, :listen, :map_color, :map_icon, :notes, :x, :y, :z])
    |> validate_required([:name, :description, :listen, :x, :y, :z, :zone_id])
    |> foreign_key_constraint(:zone_id)
  end

  def publish_changeset(struct) do
    struct
    |> change()
    |> put_change(:live_at, DateTime.truncate(DateTime.utc_now(), :second))
  end
end

defmodule ExVenture.Rooms do
  @moduledoc """
  CRUD Rooms
  """

  import Ecto.Query

  alias ExVenture.Repo
  alias ExVenture.Rooms.Room

  @doc """
  Get all rooms, paginated
  """
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})

    Room
    |> order_by([r], asc: r.zone_id, asc: r.name)
    |> preload([:zone])
    |> Repo.paginate(opts[:page], opts[:per])
  end

  @doc """
  Get a room
  """
  def get(id) do
    case Repo.get(Room, id) do
      nil ->
        {:error, :not_found}

      room ->
        {:ok, Repo.preload(room, [:zone])}
    end
  end

  @doc """
  Create a new room
  """
  def create(zone, params) do
    zone
    |> Ecto.build_assoc(:rooms)
    |> Room.create_changeset(params)
    |> Repo.insert()
  end

  @doc """
  Publish the room

  When a room is published, it will startup inside the game.
  """
  def publish(room) do
    room
    |> Room.publish_changeset()
    |> Repo.update()
  end
end
