defmodule Data.QuestRelationTest do
  use Data.ModelCase

  alias Data.QuestRelation

  describe "validations" do
    test "does not allow child and parent to match" do
      changeset = %QuestRelation{} |> QuestRelation.changeset(%{parent_id: 1, child_id: 1})
      assert changeset.errors[:parent_id]
      assert changeset.errors[:child_id]
    end
  end
end
