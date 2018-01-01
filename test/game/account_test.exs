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

  describe "online playing time" do
    test "updating the global time" do
      user = create_user(%{name: "user", password: "password"})

      Account.update_time_online(user, Timex.now() |> Timex.shift(minutes: -5), Timex.now())

      user = Repo.get(User, user.id)
      assert user.seconds_online == 300
    end

    test "records a full session separately" do
      user = create_user(%{name: "user", password: "password"})

      started_at = Timex.now() |> Timex.shift(minutes: -5)
      Account.save_session(user, user.save, started_at, Timex.now())

      user =
        User
        |> Repo.get(user.id)
        |> Repo.preload([:sessions])
      session = List.first(user.sessions)

      assert session.seconds_online == 300
      assert session.started_at == started_at
    end
  end
end
