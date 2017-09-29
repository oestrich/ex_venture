defmodule Data.ClassTest do
  use Data.ModelCase

  alias Data.Class

  test "validate stats" do
    changeset = %Class{} |> Class.changeset(%{})
    assert changeset.errors[:each_level_stats]

    changeset = %Class{} |> Class.changeset(%{stats: %{}})
    assert changeset.errors[:each_level_stats]

    stats = base_stats()
    changeset = %Class{} |> Class.changeset(%{each_level_stats: stats})
    refute changeset.errors[:each_level_stats]
  end
end
