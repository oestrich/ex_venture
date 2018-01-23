defmodule Data.Shop do
  @moduledoc """
  Shop Schema
  """

  use Data.Schema

  alias Data.Room
  alias Data.ShopItem

  schema "shops" do
    field(:name, :string)

    has_many(:shop_items, ShopItem)

    belongs_to(:room, Room)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:room_id, :name])
    |> validate_required([:room_id, :name])
    |> foreign_key_constraint(:room_id)
  end

  @doc """
  Determine if a lookup string matches the shop's name

  Checks the downcased name

  Example:

      iex> Data.Shop.matches?(%{name: "Tree Stand Shop"}, "tree stand shop")
      true

      iex> Data.Shop.matches?(%{name: "Tree Stand Shop"}, "tree sta")
      true

      iex> Data.Shop.matches?(%{name: "Tree Stand Shop"}, "hole in the")
      false
  """
  @spec matches?(t(), String.t()) :: Item.t() | nil
  def matches?(shop, lookup) do
    String.starts_with?(shop.name |> String.downcase(), lookup |> String.downcase())
  end
end
