defmodule Data.QuestStep do
  @moduledoc """
  Quest Step schema
  """

  use Data.Schema

  alias Data.Item
  alias Data.NPC
  alias Data.Quest

  @types ["item/collect", "npc/kill"]

  schema "quest_steps" do
    field :type, :string
    field :count, :integer

    belongs_to :quest, Quest
    belongs_to :item, Item
    belongs_to :npc, NPC

    timestamps()
  end

  def types(), do: @types

  def changeset(struct, params) do
    struct
    |> cast(params, [:type, :count, :quest_id, :item_id, :npc_id])
    |> validate_required([:quest_id])
    |> validate_inclusion(:type, @types)
    |> validate_type()
    |> foreign_key_constraint(:quest_id)
    |> foreign_key_constraint(:item_id)
    |> foreign_key_constraint(:npc_id)
  end

  def validate_type(changeset) do
    case get_field(changeset, :type) do
      "item/collect" -> changeset |> validate_required([:item_id, :count])
      "npc/kill" -> changeset |> validate_required([:npc_id, :count])
      _ -> changeset
    end
  end
end
