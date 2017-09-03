defmodule Data.Zone do
  @moduledoc """
  Zone schema
  """

  use Data.Schema

  alias Data.Room
  alias Data.ZoneNPC

  schema "zones" do
    field :name, :string

    has_many :rooms, Room
    has_many :zone_npcs, ZoneNPC

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end
