defmodule Data.NPCItem do
  @moduledoc """
  NPC Item Schema
  """

  use Data.Schema

  alias Data.Item
  alias Data.NPC

  schema "npc_items" do
    field :drop_rate, :integer, default: 10

    belongs_to :npc, NPC
    belongs_to :item, Item

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:npc_id, :item_id, :drop_rate])
    |> validate_required([:npc_id, :item_id, :drop_rate])
    |> validate_inclusion(:drop_rate, 0..100)
    |> foreign_key_constraint(:npc_id)
    |> foreign_key_constraint(:item_id)
  end

  def update_changeset(struct, params) do
    struct
    |> cast(params, [:drop_rate])
    |> validate_required([:drop_rate])
    |> validate_inclusion(:drop_rate, 0..100)
  end
end
