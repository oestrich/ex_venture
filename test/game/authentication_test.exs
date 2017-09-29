defmodule Game.AuthenticationTest do
  use Data.ModelCase

  alias Game.Authentication

  setup do
    fighter = create_class()
    user = create_user(%{name: "user", password: "password", class_id: fighter.id})
    {:ok, %{user: user}}
  end

  test "finds and validates a user", %{user: user} do
    assert Authentication.find_and_validate("user", "password").id == user.id
  end

  test "password is wrong" do
    assert Authentication.find_and_validate("user", "p@ssword") == {:error, :invalid}
  end

  test "name is wrong" do
    assert Authentication.find_and_validate("user", "p@ssword") == {:error, :invalid}
  end

  test "ensures stats are defaulted", %{user: user} do
    {:ok, _user} = user |> Ecto.Changeset.change(%{save: %{user.save | stats: %{}}}) |> Repo.update

    user = Authentication.find_and_validate("user", "password")
    assert user.save.stats.move_points == 10
    assert user.save.stats.max_move_points == 10
  end
end
