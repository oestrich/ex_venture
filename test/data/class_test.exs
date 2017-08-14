defmodule Data.ClassTest do
  use Data.ModelCase

  alias Data.Class

  test "validate stats" do
    changeset = %Class{} |> Class.changeset(%{})
    assert changeset.errors[:starting_stats]

    changeset = %Class{} |> Class.changeset(%{stats: %{}})
    assert changeset.errors[:starting_stats]

    changeset = %Class{} |> Class.changeset(%{starting_stats: %{health: 25, max_health: 25, strength: 13, dexterity: 10}})
    refute changeset.errors[:starting_stats]
  end
end
