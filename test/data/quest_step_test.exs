defmodule Data.QuestStepTest do
  use Data.ModelCase

  alias Data.QuestStep

  describe "type validations" do
    test "npc/kill requires an npc and count" do
      changeset = %QuestStep{} |> QuestStep.changeset(%{type: "npc/kill"})
      assert changeset.errors[:npc_id]
      assert changeset.errors[:count]

      changeset = %QuestStep{} |> QuestStep.changeset(%{type: "npc/kill", count: 4, npc_id: 4})
      refute changeset.errors[:npc_id]
      refute changeset.errors[:count]
    end

    test "item/collect requires an item and count" do
      changeset = %QuestStep{} |> QuestStep.changeset(%{type: "item/collect"})
      assert changeset.errors[:item_id]
      assert changeset.errors[:count]

      changeset = %QuestStep{} |> QuestStep.changeset(%{type: "item/collect", count: 4, item_id: 4})
      refute changeset.errors[:item_id]
      refute changeset.errors[:count]
    end
  end
end
