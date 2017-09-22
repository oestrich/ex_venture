defmodule Data.Room do
  @moduledoc """
  Room Schema
  """

  use Data.Schema

  alias Data.Exit
  alias Data.Shop
  alias Data.Zone

  schema "rooms" do
    field :name, :string
    field :description, :string
    field :currency, :integer
    field :item_ids, {:array, :integer}

    field :players, {:array, :tuple}, virtual: true
    field :items, {:array, :map}, virtual: true

    field :x, :integer
    field :y, :integer
    field :is_zone_exit, :boolean

    field :exits, {:array, Exit}, virtual: true

    has_many :npc_spawners, Data.NPCSpawner
    has_many :room_items, Data.RoomItem
    has_many :shops, Shop

    belongs_to :zone, Zone

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:zone_id, :name, :description, :x, :y, :is_zone_exit, :currency, :item_ids])
    |> ensure_item_ids
    |> ensure(:currency, 0)
    |> validate_required([:zone_id, :name, :description, :currency, :x, :y])
  end

  def exits(room) do
    ["north", "east", "south", "west"]
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
