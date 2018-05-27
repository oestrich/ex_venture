defmodule Game.AuthenticationTest do
  use Data.ModelCase

  alias Game.Authentication

  setup do
    fighter = create_class()
    user = create_user(%{name: "user", password: "password", class_id: fighter.id})
    {:ok, %{user: user}}
  end

  test "ensures stats are defaulted", %{user: user} do
    {:ok, user} = user |> Ecto.Changeset.change(%{save: %{user.save | stats: %{}}}) |> Repo.update

    user = Authentication.find_user(user.id)

    assert user.save.stats.move_points == 20
    assert user.save.stats.max_move_points == 20
  end
end
