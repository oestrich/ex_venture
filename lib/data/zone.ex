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
    field :starting_level, :integer, default: 1
    field :ending_level, :integer, default: 1

    has_many :rooms, Room
    has_many :npc_spawners, NPCSpawner

    belongs_to :graveyard, Room

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :description, :graveyard_id, :starting_level, :ending_level])
    |> validate_required([:name, :description])
  end
end
