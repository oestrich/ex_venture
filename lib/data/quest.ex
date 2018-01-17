defmodule Data.Quest do
  @moduledoc """
  Quest schema
  """

  use Data.Schema

  alias Data.NPC
  alias Data.QuestRelation
  alias Data.QuestStep

  schema "quests" do
    field :name, :string
    field :description, :string
    field :completed_message, :string
    field :level, :integer
    field :experience, :integer

    belongs_to :giver, NPC

    has_many :quest_steps, QuestStep

    has_many :parent_relations, QuestRelation, foreign_key: :child_id
    has_many :parents, through: [:parent_relations, :parent]

    has_many :child_relations, QuestRelation, foreign_key: :parent_id
    has_many :children, through: [:child_relations, :child]

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :description, :completed_message, :level, :experience, :giver_id])
    |> validate_required([:name, :description, :completed_message, :level, :experience, :giver_id])
    |> foreign_key_constraint(:giver_id)
  end
end
