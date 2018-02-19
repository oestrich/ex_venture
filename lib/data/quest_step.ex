defmodule Data.QuestStep do
  @moduledoc """
  Quest Step schema
  """

  use Data.Schema

  alias Data.Item
  alias Data.NPC
  alias Data.Room
  alias Data.Quest

  @types [
    "item/collect",
    "item/give",
    "item/have",
    "npc/kill",
    "room/explore"
  ]

  schema "quest_steps" do
    field(:type, :string)
    field(:count, :integer)

    belongs_to(:quest, Quest)
    belongs_to(:item, Item)
    belongs_to(:npc, NPC)
    belongs_to(:room, Room)

    timestamps()
  end

  def types(), do: @types

  def changeset(struct, params) do
    struct
    |> cast(params, [:type, :count, :quest_id, :item_id, :npc_id, :room_id])
    |> validate_required([:quest_id])
    |> validate_inclusion(:type, @types)
    |> validate_type()
    |> foreign_key_constraint(:quest_id)
    |> foreign_key_constraint(:item_id)
    |> foreign_key_constraint(:npc_id)
    |> foreign_key_constraint(:room_id)
    |> unique_constraint(:item_id, name: :quest_steps_quest_id_item_id_index)
    |> unique_constraint(:npc_id, name: :quest_steps_quest_id_npc_id_index)
    |> unique_constraint(:room_id, name: :quest_steps_quest_id_room_id_index)
  end

  def validate_type(changeset) do
    case get_field(changeset, :type) do
      "item/collect" ->
        changeset |> validate_required([:item_id, :count])

      "item/give" ->
        changeset |> validate_required([:item_id, :npc_id, :count])

      "item/have" ->
        changeset |> validate_required([:item_id, :count])

      "npc/kill" ->
        changeset |> validate_required([:npc_id, :count])

      "room/explore" ->
        changeset |> validate_required([:room_id])

      _ ->
        changeset
    end
  end
end
