defmodule Data.ShopItem do
  @moduledoc """
  Shop Schema
  """

  use Data.Schema

  alias Data.Item
  alias Data.Shop

  schema "shop_items" do
    field :price, :integer
    field :quantity, :integer

    belongs_to :shop, Shop
    belongs_to :item, Item

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:shop_id, :item_id, :price, :quantity])
    |> validate_required([:shop_id, :item_id, :price, :quantity])
    |> foreign_key_constraint(:shop_id)
    |> foreign_key_constraint(:item_id)
  end

  def update_changeset(struct, params) do
    struct
    |> cast(params, [:price, :quantity])
    |> validate_required([:price, :quantity])
  end
end
