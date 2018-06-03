defmodule Data.Zone do
  @moduledoc """
  Zone schema
  """

  use Data.Schema

  alias Data.NPCSpawner
  alias Data.Room
  alias Data.Zone.MapCell

  @types ["rooms", "overworld"]

  schema "zones" do
    field(:type, :string, default: "rooms")
    field(:name, :string)
    field(:description, :string)
    field(:starting_level, :integer, default: 1)
    field(:ending_level, :integer, default: 1)
    field(:map_layer_names, :map, default: %{})
    field(:overworld_map, {:array, MapCell})

    has_many(:rooms, Room)
    has_many(:npc_spawners, NPCSpawner)

    belongs_to(:graveyard, Room)

    timestamps()
  end

  def types(), do: @types

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :type,
      :name,
      :description,
      :graveyard_id,
      :starting_level,
      :ending_level,
      :map_layer_names
    ])
    |> validate_required([:type, :name, :description, :map_layer_names])
    |> validate_inclusion(:type, @types)
  end

  def map_changeset(struct, params) do
    struct
    |> cast(params, [:overworld_map])
    |> validate_required([:overworld_map])
    |> validate_inclusion(:type, ["overworld"], message: "must be an overworld to add a map")
  end
end
