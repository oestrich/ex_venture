defmodule Data.ItemTag do
  @moduledoc """
  Item Schema
  """

  use Data.Schema

  alias Data.Effect
  alias Data.Item
  alias Data.ItemTagging
  alias Data.Stats

  schema "item_tags" do
    field :name, :string
    field :description, :string
    field :type, :string
    field :stats, Stats
    field :effects, {:array, Effect}

    has_many :item_taggings, ItemTagging
    has_many :items, through: [:item_taggings, :item]

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :description, :type, :stats, :effects])
    |> validate_required([:name, :description, :type, :stats, :effects])
    |> validate_inclusion(:type, Item.types())
    |> Item.validate_stats()
    |> Effect.validate_effects()
    |> Item.validate_effects()
  end
end
