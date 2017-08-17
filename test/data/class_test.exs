defmodule Data.ClassTest do
  use Data.ModelCase

  alias Data.Class

  test "validate stats" do
    changeset = %Class{} |> Class.changeset(%{})
    assert changeset.errors[:starting_stats]

    changeset = %Class{} |> Class.changeset(%{stats: %{}})
    assert changeset.errors[:starting_stats]

    stats =%{health: 25, max_health: 25, strength: 13, dexterity: 10, skill_points: 10, max_skill_points: 10} 
    changeset = %Class{} |> Class.changeset(%{starting_stats: stats})
    refute changeset.errors[:starting_stats]
  end
end
