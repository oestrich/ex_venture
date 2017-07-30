defmodule Data.ItemTest do
  use ExUnit.Case

  alias Data.Item

  test "validate type" do
    changeset = %Item{} |> Item.changeset(%{})
    assert changeset.errors[:type]

    changeset = %Item{} |> Item.changeset(%{type: "not-found"})
    assert changeset.errors[:type]
  end

  test "validates item stats" do
    changeset = %Item{} |> Item.changeset(%{})
    assert changeset.errors[:stats]

    changeset = %Item{} |> Item.changeset(%{type: "armor", stats: %{}})
    assert changeset.errors[:stats]

    changeset = %Item{} |> Item.changeset(%{type: "armor", stats: %{slot: :chest}})
    refute changeset.errors[:stats]
  end
end
