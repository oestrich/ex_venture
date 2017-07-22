defmodule Data.RoomItem do
  use Data.Schema

  schema "room_items" do
    belongs_to :room, Data.Room
    belongs_to :item, Data.Item

    field :spawn, :boolean
    field :interval, :integer

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:room_id, :item_id, :spawn, :interval])
    |> validate_required([:room_id, :item_id, :spawn])
  end
end
