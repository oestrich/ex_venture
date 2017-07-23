defmodule Data.Room do
  use Data.Schema

  schema "rooms" do
    field :name, :string
    field :description, :string
    field :item_ids, {:array, :integer}

    field :players, {:array, :tuple}, virtual: true
    field :items, {:array, :map}, virtual: true

    has_many :room_items, Data.RoomItem

    belongs_to :north, __MODULE__
    belongs_to :east, __MODULE__
    belongs_to :south, __MODULE__
    belongs_to :west, __MODULE__

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :description, :north_id, :east_id, :south_id, :west_id, :item_ids])
    |> ensure_item_ids
    |> validate_required([:name, :description])
  end

  def exits(room) do
    ["north", "east", "south", "west"]
    |> Enum.filter(fn (direction) ->
      Map.get(room, :"#{direction}_id") != nil
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
