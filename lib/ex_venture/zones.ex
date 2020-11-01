defmodule ExVenture.Zones.Zone do
  @moduledoc """
  Schema for Zones
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias ExVenture.Rooms.Room

  schema "zones" do
    field(:name, :string)
    field(:description, :string)

    belongs_to(:graveyard, Room)
    has_many(:rooms, Room)

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
end

defmodule ExVenture.Zones do
  @moduledoc """
  CRUD Zones
  """

  alias ExVenture.Repo
  alias ExVenture.Zones.Zone

  def new(), do: Ecto.Changeset.change(%Zone{}, %{})

  def edit(zone), do: Ecto.Changeset.change(zone, %{})

  @doc """
  Get all zones, paginated
  """
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})

    Repo.paginate(Zone, opts[:page], opts[:per])
  end

  @doc """
  Get a zone
  """
  def get(id) do
    case Repo.get(Zone, id) do
      nil ->
        {:error, :not_found}

      zone ->
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
  def update(zone, params) do
    zone
    |> Zone.update_changeset(params)
    |> Repo.update()
  end
end
