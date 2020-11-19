defmodule ExVenture.Zones.Zone do
  @moduledoc """
  Schema for Zones
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias ExVenture.Rooms.Room
  alias ExVenture.StagedChanges.StagedChange

  schema "zones" do
    field(:live_at, :utc_datetime)

    field(:name, :string)
    field(:description, :string)

    belongs_to(:graveyard, Room)
    has_many(:rooms, Room)

    has_many(:staged_changes, {"zone_staged_changes", StagedChange}, foreign_key: :struct_id)

    timestamps()
  end

  def create_changeset(struct, params) do
    struct
    |> cast(params, [:name, :description, :graveyard_id])
    |> validate_required([:name, :description])
    |> foreign_key_constraint(:graveyard_id)
  end

  def update_changeset(struct, params) do
    struct
    |> cast(params, [:name, :description, :graveyard_id])
    |> validate_required([:name, :description])
    |> foreign_key_constraint(:graveyard_id)
  end

  def publish_changeset(struct) do
    struct
    |> change()
    |> put_change(:live_at, DateTime.truncate(DateTime.utc_now(), :second))
  end
end

defmodule ExVenture.Zones do
  @moduledoc """
  CRUD Zones
  """

  import Ecto.Query

  alias ExVenture.MiniMap
  alias ExVenture.Repo
  alias ExVenture.StagedChanges
  alias ExVenture.Zones.Zone

  def new(), do: Ecto.Changeset.change(%Zone{}, %{})

  def edit(zone), do: Ecto.Changeset.change(zone, %{})

  @doc """
  Get all zones, paginated
  """
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})

    Zone
    |> order_by([z], asc: z.name)
    |> preload(:staged_changes)
    |> Repo.paginate(opts[:page], opts[:per])
    |> staged_changes()
  end

  defp staged_changes(%{page: zones, pagination: pagination}) do
    zones = Enum.map(zones, &StagedChanges.apply/1)
    %{page: zones, pagination: pagination}
  end

  defp staged_changes(zones) do
    Enum.map(zones, &StagedChanges.apply/1)
  end

  @doc """
  Get a zone
  """
  def get(id) do
    case Repo.get(Zone, id) do
      nil ->
        {:error, :not_found}

      zone ->
        zone =
          zone
          |> Repo.preload([:rooms, :staged_changes])
          |> StagedChanges.apply()

        {:ok, zone}
    end
  end

  @doc """
  Create a new zone
  """
  def create(params) do
    %Zone{}
    |> Zone.create_changeset(params)
    |> Repo.insert()
  end

  @doc """
  Update a zone
  """
  def update(%{live_at: nil} = zone, params) do
    zone
    |> Zone.update_changeset(params)
    |> Repo.update()
  end

  def update(zone, params) do
    zone
    |> Zone.update_changeset(params)
    |> StagedChanges.record_changes()
  end

  @doc """
  Publish the zone

  When a zone is published, it will startup inside the game.
  """
  def publish(zone) do
    zone
    |> Zone.publish_changeset()
    |> Repo.update()
  end

  def make_mini_map(zone) do
    zone = Repo.preload(zone, :rooms)

    mini_map = %MiniMap{id: zone.id}

    cells =
      Enum.into(zone.rooms, %{}, fn room ->
        cell = %MiniMap.Cell{
          id: room.id,
          map_color: room.map_color,
          map_icon: room.map_icon,
          name: room.name,
          x: room.x,
          y: room.y,
          z: room.z
        }

        {{room.x, room.y, room.z}, cell}
      end)

    mini_map = %{mini_map | cells: cells}

    {{min_x, max_x}, {min_y, max_y}, {min_z, max_z}} = MiniMap.size_of_map(mini_map)

    mini_map
    |> Map.put(:min_x, min_x)
    |> Map.put(:max_x, max_x)
    |> Map.put(:min_y, min_y)
    |> Map.put(:max_y, max_y)
    |> Map.put(:min_z, min_z)
    |> Map.put(:max_z, max_z)
  end
end
