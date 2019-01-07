defmodule Game.AccountTest do
  use Data.ModelCase

  alias Data.Character
  alias Data.Item
  alias Data.Proficiency
  alias Data.User
  alias Game.Account

  describe "creating an account" do
    test "successfully" do
      create_config(:starting_save, base_save() |> Poison.encode!)
      human = create_race()
      fighter = create_class()

      {:ok, user, character} = Account.create(%{name: "user", email: "user@example.com", password: "password"}, %{race: human, class: fighter})

      assert user.name == "user"
      assert user.email == "user@example.com"
      assert user.password_hash

      assert character.save
      assert character.race_id == human.id
      assert character.class_id == fighter.id
    end
  end

  test "updating the save force saves it" do
    user = create_user(%{name: "user", password: "password"})
    character = create_character(user, %{name: "player"})

    character = %{character | save: %{character.save | stats: %{character.save.stats | endurance_points: 3}}}
    assert character.save.stats.endurance_points == 3

    {:ok, character} = Account.save(character, character.save)

    character = Repo.get(Character, character.id)
    assert character.save.stats.endurance_points == 3
  end

  describe "online playing time" do
    test "updating the global time" do
      user = create_user(%{name: "user", password: "password"})
      character = create_character(user, %{name: "player"})

      Account.update_time_online(character, Timex.now() |> Timex.shift(minutes: -5), Timex.now())

      character = Repo.get(Character, character.id)
      assert character.seconds_online == 300
    end

    test "records a full session separately" do
      user = create_user(%{name: "user", password: "password"})
      character = create_character(user, %{name: "player"})

      started_at = Timex.now() |> Timex.shift(minutes: -5)
      Account.save_session(user, character, character.save, started_at, Timex.now(), %{commands: %{Game.Command.Look => 1}})

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

      character = create_character(user)

      start_and_clear_items()
      potion = create_item(%{name: "Potion", is_usable: true, amount: 3})
      insert_item(potion)

      start_and_clear_skills()

      %{user: user, character: character, potion: potion}
    end

    test "add amount to the instance if the item is usable", %{character: character, potion: potion} do
      character = %{character | save: %{character.save | items: [%Item.Instance{id: potion.id, created_at: Timex.now()}]}}

      character = Account.migrate_items(character)

      assert [%Item.Instance{id: _, amount: 3} | _] = character.save.items
    end
  end

  describe "migrating known skills on load" do
    setup do
      user = create_user()
      character = create_character(user)

      start_and_clear_skills()

      %{user: user, character: character}
    end

    test "ensure class skills are present", %{character: character} do
      skill = create_skill()
      insert_skill(skill)

      create_class_skill(character.class, skill)

      character = Account.migrate_skills(character)

      assert character.save.skill_ids == [skill.id]
    end

    test "ensure global skills are present", %{character: character} do
      skill = create_skill(%{is_global: true})
      insert_skill(skill)

      character = Account.migrate_skills(character)

      assert character.save.skill_ids == [skill.id]
    end

    test "ensure race skills are present", %{character: character} do
      skill = create_skill()
      insert_skill(skill)

      create_race_skill(character.race, skill)

      character = Account.migrate_skills(character)

      assert character.save.skill_ids == [skill.id]
    end
  end

  describe "migrating known proficiencies" do
    setup do
      user = create_user()
      character = create_character(user)

      start_and_clear_proficiencies()

      %{user: user, character: character}
    end

    test "adds class proficiencies that are the characters level and below", %{character: character} do
      proficiency1 = create_proficiency() |> insert_proficiency()
      proficiency2 = create_proficiency() |> insert_proficiency()

      create_class_proficiency(character.class, proficiency1, %{level: 1, ranks: 2})
      create_class_proficiency(character.class, proficiency2, %{level: 2, ranks: 3})

      character = Account.migrate_proficiencies(character)

      assert [%{ranks: 2}] = character.save.proficiencies
    end

    test "does not overwrite existing proficiencies", %{character: character} do
      proficiency = create_proficiency() |> insert_proficiency()

      create_class_proficiency(character.class, proficiency, %{level: 1, ranks: 2})

      save = %{character.save | proficiencies: [%Proficiency.Instance{proficiency_id: proficiency.id, ranks: 1}]}
      character = %{character | save: save}

      character = Account.migrate_proficiencies(character)

      assert [%{ranks: 1}] = character.save.proficiencies
    end
  end
end
