defmodule Web.UserTest do
  use Data.ModelCase

  alias Data.QuestProgress
  alias Game.Account
  alias Game.Session
  alias Web.User

  setup do
    user = create_user(%{name: "user", password: "password", flags: ["admin"]})
    %{user: user}
  end

  describe "verifying the passsword" do
    test "valid", %{user: user} do
      assert user.id == User.find_and_validate(user.name, "password").id
    end

    test "invalid", %{user: user} do
      assert {:error, :invalid} = User.find_and_validate(user.name, "p@ssword")
    end
  end

  test "changing password", %{user: user} do
    {:ok, user} = User.change_password(user, "password", %{password: "apassword", password_confirmation: "apassword"})

    assert user.id == User.find_and_validate(user.name, "apassword").id
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

  test "update a player", %{user: user} do
    {:ok, user} = User.update(user.id, %{"email" => "new@example.com"})

    assert user.email == "new@example.com"
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

  describe "generate a one time password" do
    test "create a new password", %{user: user} do
      {:ok, password} = User.create_one_time_password(user)

      assert password.password
      assert is_nil(password.used_at)
    end

    test "creating a new password expires old ones", %{user: user} do
      {:ok, old_password} = User.create_one_time_password(user)
      {:ok, _password} = User.create_one_time_password(user)

      old_password = Repo.get(Data.User.OneTimePassword, old_password.id)
      assert old_password.used_at
    end
  end

  describe "check totp token" do
    setup %{user: user} do
      user = User.create_totp_secret(user)
      %{user: user}
    end

    test "does not create duplicate secrets while it hasn't been verified yet", %{user: user} do
      original_secret = user.totp_secret
      user = User.create_totp_secret(user)
      assert user.totp_secret == original_secret
    end

    test "validate a token", %{user: user} do
      secret = Base.encode32(Base.decode32!(user.totp_secret, padding: false))
      token = :pot.totp(secret)

      assert User.valid_totp_token?(user, token)
    end

    test "validate a token - invalid token", %{user: user} do
      refute User.valid_totp_token?(user, "abc123")
    end

    test "verify the token", %{user: user} do
      user = User.totp_token_verified(user)

      assert user.totp_verified_at
      assert User.totp_verified?(user)
    end
  end
end
