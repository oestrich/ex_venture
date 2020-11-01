defmodule ExVenture.Rooms.Room do
  @moduledoc """
  Schema for Rooms
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias ExVenture.Zones.Zone

  schema "rooms" do
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
end

defmodule ExVenture.Rooms do
  @moduledoc """
  CRUD Rooms
  """

  alias ExVenture.Repo
  alias ExVenture.Rooms.Room

  @doc """
  Create a new room
  """
  def create(zone, params) do
    zone
    |> Ecto.build_assoc(:rooms)
    |> Room.create_changeset(params)
    |> Repo.insert()
  end
end
