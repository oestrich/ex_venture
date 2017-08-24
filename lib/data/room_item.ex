defmodule Data.RoomItem do
  @moduledoc """
  RoomItem Schema
  """

  use Data.Schema

  schema "room_items" do
    belongs_to :room, Data.Room
    belongs_to :item, Data.Item

    field :spawn_interval, :integer

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:room_id, :item_id, :spawn_interval])
    |> validate_required([:room_id, :item_id])
  end
end
