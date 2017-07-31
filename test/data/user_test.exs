defmodule Data.UserTest do
  use Data.ModelCase

  alias Data.User

  test "valid changeset" do
    changeset = User.changeset(%User{}, %{name: "user", password: "password", save: base_save()})
    assert changeset.valid?
  end

  test "hashes the password" do
    changeset = User.changeset(%User{}, %{name: "user", password: "password", save: base_save()})
    assert changeset.changes[:password_hash]
  end

  test "validates user save" do
    changeset = %User{} |> User.changeset(%{})
    assert changeset.errors[:save]

    changeset = %User{} |> User.changeset(%{save: %{}})
    assert changeset.errors[:save]

    save = %Data.Save{room_id: 1, item_ids: [], class: Game.Class.Fighter, wearing: %{}, wielding: %{}}
    changeset = %User{} |> User.changeset(%{save: save})
    refute changeset.errors[:save]
  end
end
