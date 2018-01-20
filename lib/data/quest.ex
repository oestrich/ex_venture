defmodule Data.Quest do
  @moduledoc """
  Quest schema
  """

  use Data.Schema

  alias Data.Conversation
  alias Data.NPC
  alias Data.QuestRelation
  alias Data.QuestStep

  schema "quests" do
    field :name, :string
    field :description, :string
    field :completed_message, :string
    field :level, :integer
    field :experience, :integer
    field :conversations, {:array, Conversation}

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
    |> cast(params, [:name, :description, :completed_message, :level, :experience, :conversations, :giver_id])
    |> validate_required([:name, :description, :completed_message, :level, :experience, :conversations, :giver_id])
    |> validate_giver_is_a_giver()
    |> Conversation.validate_conversations()
    |> validate_conversations()
    |> foreign_key_constraint(:giver_id)
  end

  defp validate_giver_is_a_giver(changeset) do
    case get_field(changeset, :giver_id) do
      nil -> changeset
      giver_id ->
        case Repo.get(NPC, giver_id) do
          %{is_quest_giver: true} -> changeset
          _ -> add_error(changeset, :giver_id, "must be marked as a quest giver")
        end
    end
  end

  defp validate_conversations(changeset) do
    case get_field(changeset, :conversations) do
      nil -> changeset
      conversations -> _validate_conversations(changeset, conversations)
    end
  end

  defp _validate_conversations(changeset, conversations) do
    case Conversation.valid_for_quest?(conversations) do
      true -> changeset
      false -> add_error(changeset, :conversations, "must include one conversation that has a trigger with quest")
    end
  end
end
