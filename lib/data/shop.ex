defmodule Data.Shop do
  @moduledoc """
  Shop Schema
  """

  use Data.Schema

  alias Data.Room
  alias Data.ShopItem

  schema "shops" do
    field :name, :string

    has_many :shop_items, ShopItem

    belongs_to :room, Room

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:room_id, :name])
    |> validate_required([:room_id, :name])
  end
end
