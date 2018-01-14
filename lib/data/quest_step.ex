defmodule Data.QuestStep do
  @moduledoc """
  Quest Step schema
  """

  use Data.Schema

  alias Data.Item
  alias Data.NPC
  alias Data.Quest

  schema "quest_steps" do
    field :type, :string
    field :count, :integer

    belongs_to :quest, Quest
    belongs_to :item, Item
    belongs_to :npc, NPC

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:type, :count, :quest_id, :item_id, :npc_id])
    |> validate_required([:quest_id])
    |> foreign_key_constraint(:quest_id)
  end
end
