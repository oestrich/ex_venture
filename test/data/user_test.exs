defmodule Data.UserTest do
  use Data.ModelCase

  alias Data.User

  test "valid changeset" do
    changeset = User.changeset(%User{}, %{name: "user", password: "password"})
    assert changeset.valid?
  end

  test "hashes the password" do
    changeset = User.changeset(%User{}, %{name: "user", password: "password"})
    assert changeset.changes[:password_hash]
  end

  test "ensures flags exist" do
    changeset = %User{} |> User.changeset(%{})
    assert changeset.changes.flags == []
  end

  test "ensures token exists" do
    changeset = %User{} |> User.changeset(%{})
    refute is_nil(changeset.changes.token)
  end

  test "validates user's name is a single word" do
    changeset = %User{} |> User.changeset(%{name: "user"})
    refute changeset.errors[:name]

    changeset = %User{} |> User.changeset(%{name: "user name"})
    assert changeset.errors[:name]
  end
end
