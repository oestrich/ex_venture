defmodule Data.Zone do
  @moduledoc """
  Zone schema
  """

  use Data.Schema

  alias Data.Exit
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

    field(:exits, {:array, Exit}, virtual: true)

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
    |> maybe_default_overworld()
  end

  def map_changeset(struct, params) do
    struct
    |> cast(params, [:overworld_map])
    |> validate_required([:overworld_map])
    |> validate_inclusion(:type, ["overworld"], message: "must be an overworld to add a map")
  end

  defp maybe_default_overworld(changeset) do
    case get_field(changeset, :type) do
      "rooms" ->
        changeset

      "overworld" ->
        default_overworld(changeset)
    end
  end

  defp default_overworld(changeset) do
    case get_field(changeset, :overworld_map) do
      nil ->
        put_change(changeset, :overworld_map, default_map())

      _ ->
        changeset
    end
  end

  def default_map() do
    Enum.flat_map(0..99, fn x ->
      Enum.map(0..49, fn y ->
        %{x: x, y: y, s: " ", c: nil}
      end)
    end)
  end
end
