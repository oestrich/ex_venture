defmodule Data.QuestRelation do
  @moduledoc """
  Quest relation schema
  """

  use Data.Schema

  alias Data.Quest

  schema "quest_relations" do
    belongs_to :parent, Quest
    belongs_to :child, Quest

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:parent_id, :child_id])
    |> validate_required([:parent_id, :child_id])
    |> validate_not_same()
    |> foreign_key_constraint(:parent_id)
    |> foreign_key_constraint(:child_id)
    |> unique_constraint(:parent_id, name: :quest_relations_parent_id_child_id_index) 
    |> unique_constraint(:child_id, name: :quest_relations_parent_id_child_id_index) 
  end

  defp validate_not_same(changeset) do
    case get_field(changeset, :parent_id) == get_field(changeset, :child_id) do
      false -> changeset
      true ->
        changeset
        |> add_error(:parent_id, "cannot match child")
        |> add_error(:child_id, "cannot match parent")
    end
  end
end
