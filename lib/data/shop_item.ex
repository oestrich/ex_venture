defmodule Data.ShopItem do
  @moduledoc """
  Shop Schema
  """

  use Data.Schema

  alias Data.Item
  alias Data.Shop

  schema "shops" do
    belongs_to :shop, Shop
    belongs_to :item, Item

    timestamps()
  end
end
