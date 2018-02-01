defmodule Web.UserTest do
  use Data.ModelCase

  alias Data.QuestProgress
  alias Game.Account
  alias Game.Authentication
  alias Game.Session
  alias Web.User

  setup do
    user = create_user(%{name: "user", password: "password", flags: ["admin"]})
    %{user: user}
  end

  test "changing password", %{user: user} do
    {:ok, user} = User.change_password(user, "password", %{password: "apassword", password_confirmation: "apassword"})

    assert user.id == Authentication.find_and_validate(user.name, "apassword").id
  end

  test "changing password - bad current password", %{user: user} do
    assert {:error, :invalid} = User.change_password(user, "p@ssword", %{password: "apassword", password_confirmation: "apassword"})
  end

  test "disconnecting connected players", %{user: user} do
    Session.Registry.register(user)

    User.disconnect()

    assert_receive {:"$gen_cast", {:disconnect, [force: true]}}
  end

  test "create a new player" do
    create_config(:starting_save, base_save() |> Poison.encode!)
    class = create_class()
    race = create_race()

    {:ok, user} = User.create(%{
      "name" => "player",
      "email" => "",
      "password" => "password",
      "password_confirmation" => "password",
      "class_id" => class.id,
      "race_id" => race.id,
    })

    assert user.name == "player"
  end

  describe "reset a user" do
    setup do
      create_config(:starting_save, base_save() |> Poison.encode!)
      :ok
    end

    test "resets the save", %{user: user} do
      save = %{user.save | level: 2}
      {:ok, user} = Account.save(user, save)

      {:ok, user} = User.reset(user.id)

      assert user.save.level == 1
    end

    test "resets quests", %{user: user} do
      guard = create_npc(%{is_quest_giver: true})
      quest = create_quest(guard)
      create_quest_progress(user, quest)

      {:ok, _user} = User.reset(user.id)

      assert Data.Repo.all(QuestProgress) == []
    end
  end
end
