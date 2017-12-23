defmodule Data.ItemAspecting do
  @moduledoc """
  Item Aspecting Schema
  """

  use Data.Schema

  alias Data.Item
  alias Data.ItemAspect

  schema "item_aspectings" do
    belongs_to :item, Item
    belongs_to :item_aspect, ItemAspect

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:item_id, :item_aspect_id])
    |> validate_required([:item_id, :item_aspect_id])
    |> foreign_key_constraint(:item_id)
    |> foreign_key_constraint(:item_aspect_id)
    |> unique_constraint(:item_aspect_id, name: :item_taggings_item_id_item_tag_id_index)
  end
end
