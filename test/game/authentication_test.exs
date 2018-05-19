defmodule Game.AuthenticationTest do
  use Data.ModelCase

  alias Game.Authentication
  alias Web.User

  setup do
    fighter = create_class()
    user = create_user(%{name: "user", password: "password", class_id: fighter.id})
    {:ok, %{user: user}}
  end

  test "finds and validates a user", %{user: user} do
    {:ok, password} = User.create_one_time_password(user)
    assert Authentication.find_and_validate("user", password.password).id == user.id
  end

  test "user is case insensitive", %{user: user} do
    {:ok, password} = User.create_one_time_password(user)
    assert Authentication.find_and_validate("uSer", password.password).id == user.id
  end

  test "password is wrong" do
    assert Authentication.find_and_validate("user", "p@ssword") == {:error, :invalid}
  end

  test "name is wrong" do
    assert Authentication.find_and_validate("usr", "p@ssword") == {:error, :invalid}
  end

  test "ensures stats are defaulted", %{user: user} do
    {:ok, _user} = user |> Ecto.Changeset.change(%{save: %{user.save | stats: %{}}}) |> Repo.update
    {:ok, password} = User.create_one_time_password(user)

    user = Authentication.find_and_validate("user", password.password)
    assert user.save.stats.move_points == 20
    assert user.save.stats.max_move_points == 20
  end
end
