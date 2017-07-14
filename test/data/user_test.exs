defmodule Data.UserTest do
  use Data.ModelCase

  alias Data.User

  test "valid changeset" do
    changeset = User.changeset(%User{}, %{username: "user", password: "password"})
    assert changeset.valid?
  end

  test "hashes the password" do
    changeset = User.changeset(%User{}, %{username: "user", password: "password"})
    assert changeset.changes[:password_hash]
  end
end
