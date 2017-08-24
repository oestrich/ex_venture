defmodule Data.NPCTest do
  use Data.ModelCase

  alias Data.NPC

  test "validates stats" do
    changeset = %NPC{} |> NPC.changeset(%{})
    assert changeset.errors[:stats]

    changeset = %NPC{} |> NPC.changeset(%{stats: %{}})
    assert changeset.errors[:stats]

    changeset = %NPC{} |> NPC.changeset(%{stats: base_save().stats})
    refute changeset.errors[:stats]
  end
end
