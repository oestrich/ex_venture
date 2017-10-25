defmodule Data.Room do
  @moduledoc """
  Room Schema
  """

  use Data.Schema

  alias Data.Exit
  alias Data.Shop
  alias Data.Zone

  @ecologies [
    "default",
    "ocean", "river", "lake",
    "forest", "jungle",
    "town", "inside", "road",
    "hill", "mountain",
    "field", "meadow",
    "dungeon",
  ]

  schema "rooms" do
    field :name, :string
    field :description, :string
    field :currency, :integer
    field :item_ids, {:array, :integer}

    field :players, {:array, :tuple}, virtual: true
    field :items, {:array, :map}, virtual: true

    field :x, :integer
    field :y, :integer
    field :map_layer, :integer
    field :is_zone_exit, :boolean
    field :ecology, :string

    field :exits, {:array, Exit}, virtual: true

    has_many :npc_spawners, Data.NPCSpawner
    has_many :room_items, Data.RoomItem
    has_many :shops, Shop

    belongs_to :zone, Zone

    timestamps()
  end

  def ecologies(), do: @ecologies

  def changeset(struct, params) do
    struct
    |> cast(params, [:zone_id, :name, :description, :x, :y, :map_layer, :is_zone_exit, :ecology, :currency, :item_ids])
    |> ensure_item_ids
    |> ensure(:currency, 0)
    |> ensure(:ecology, "default")
    |> validate_required([:zone_id, :name, :description, :currency, :x, :y, :map_layer, :ecology])
    |> validate_inclusion(:ecology, @ecologies)
  end

  def exits(room) do
    ["north", "east", "south", "west", "up", "down"]
    |> Enum.filter(fn (direction) ->
      Exit.exit_to(room, direction)
    end)
  end

  defp ensure_item_ids(changeset) do
    case changeset do
      %{changes: %{item_ids: _ids}} -> changeset
      %{data: %{item_ids: ids}} when ids != nil -> changeset
      _ -> put_change(changeset, :item_ids, [])
    end
  end
end
