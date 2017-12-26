defmodule Data.Zone do
  @moduledoc """
  Zone schema
  """

  use Data.Schema

  alias Data.NPCSpawner
  alias Data.Room

  schema "zones" do
    field :name, :string
    field :description, :string

    has_many :rooms, Room
    has_many :npc_spawners, NPCSpawner

    belongs_to :graveyard, Room

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :description, :graveyard_id])
    |> validate_required([:name, :description])
  end
end
