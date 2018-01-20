defmodule Data.Quest do
  @moduledoc """
  Quest schema
  """

  use Data.Schema

  alias Data.Script
  alias Data.NPC
  alias Data.QuestRelation
  alias Data.QuestStep

  schema "quests" do
    field :name, :string
    field :description, :string
    field :completed_message, :string
    field :level, :integer
    field :experience, :integer
    field :currency, :integer, default: 0
    field :script, {:array, Script.Line}

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
    |> cast(params, [:name, :description, :completed_message, :level, :experience, :currency, :script, :giver_id])
    |> validate_required([:name, :description, :completed_message, :level, :experience, :currency, :script, :giver_id])
    |> validate_giver_is_a_giver()
    |> Script.validate_script()
    |> validate_script()
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

  defp validate_script(changeset) do
    case get_field(changeset, :script) do
      nil -> changeset
      script-> _validate_script(changeset, script)
    end
  end

  defp _validate_script(changeset, script) do
    case Script.valid_for_quest?(script) do
      true -> changeset
      false -> add_error(changeset, :script, "must include one conversation that has a trigger with quest")
    end
  end
end
