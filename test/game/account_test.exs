defmodule Game.AccountTest do
  use Data.ModelCase

  alias Data.Item
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
      Account.save_session(user, user.save, started_at, Timex.now(), %{commands: %{Game.Command.Look => 1}})

      user =
        User
        |> Repo.get(user.id)
        |> Repo.preload([:sessions])
      session = List.first(user.sessions)

      assert session.seconds_online == 300
      assert Timex.diff(session.started_at, started_at, :seconds) < 1 # account for microseconds
      assert session.commands == %{"Elixir.Game.Command.Look" => 1}
    end
  end

  describe "migrating item instances on load" do
    setup do
      user = create_user(%{name: "user", password: "password"})

      start_and_clear_items()
      potion = create_item(%{name: "Potion", is_usable: true, amount: 3})
      insert_item(potion)

      %{user: user, potion: potion}
    end

    test "add amount to the instance if the item is usable", %{user: user, potion: potion} do
      user = %{user | save: %{user.save | items: [%Item.Instance{id: potion.id, created_at: Timex.now()}]}}

      user = Account.migrate_items(user)

      assert [%Item.Instance{id: _, amount: 3} | _] = user.save.items
    end
  end

  describe "migrating known skills on load" do
    setup do
      user =
        create_user(%{name: "user", password: "password"})
        |> Repo.preload([:class, :race])

      start_and_clear_skills()

      %{user: user}
    end

    test "ensure class skills are present", %{user: user} do
      skill = create_skill()
      insert_skill(skill)

      create_class_skill(user.class, skill)

      user = Account.migrate_skills(user)

      assert user.save.skill_ids == [skill.id]
    end

    test "ensure global skills are present", %{user: user} do
      skill = create_skill(%{is_global: true})
      insert_skill(skill)

      user = Account.migrate_skills(user)

      assert user.save.skill_ids == [skill.id]
    end

    test "ensure race skills are present", %{user: user} do
      skill = create_skill()
      insert_skill(skill)

      create_race_skill(user.race, skill)

      user = Account.migrate_skills(user)

      assert user.save.skill_ids == [skill.id]
    end
  end
end
