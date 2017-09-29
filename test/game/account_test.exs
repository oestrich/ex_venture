defmodule Game.AccountTest do
  use Data.ModelCase

  alias Data.User
  alias Game.Account

  test "updating the save force saves it" do
    user = create_user(%{name: "user", password: "password"})

    user = %{user | save: %{user.save | stats: %{user.save.stats | move_points: 3}}}
    assert user.save.stats.move_points == 3

    {:ok, user} = Account.save(user, user.save)

    user = Repo.get(User, user.id)
    assert user.save.stats.move_points == 3
  end
end
