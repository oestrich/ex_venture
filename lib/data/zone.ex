defmodule Data.Zone do
  @moduledoc """
  Zone schema
  """

  use Data.Schema

  alias Data.NPCSpawner
  alias Data.Room

  schema "zones" do
    field(:name, :string)
    field(:description, :string)
    field(:starting_level, :integer, default: 1)
    field(:ending_level, :integer, default: 1)
    field(:map_layer_names, :map, default: %{})

    has_many(:rooms, Room)
    has_many(:npc_spawners, NPCSpawner)

    belongs_to(:graveyard, Room)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :description, :graveyard_id, :starting_level, :ending_level, :map_layer_names])
    |> validate_required([:name, :description, :map_layer_names])
  end
end
