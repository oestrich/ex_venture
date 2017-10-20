defmodule Data.ItemTagging do
  @moduledoc """
  Item Tagging Schema
  """

  use Data.Schema

  alias Data.Item
  alias Data.ItemTag

  schema "item_taggings" do
    belongs_to :item, Item
    belongs_to :item_tag, ItemTag

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:item_id, :item_tag_id])
    |> validate_required([:item_id, :item_tag_id])
    |> foreign_key_constraint(:item_id)
    |> foreign_key_constraint(:item_tag_id)
    |> unique_constraint(:item_tag_id, name: :item_taggings_item_id_item_tag_id_index)
  end
end
