defmodule ExVenture.UsersTest do
  use ExVenture.DataCase
  use Bamboo.Test

  alias ExVenture.Users

  describe "creating new users" do
    test "registers them" do
      {:ok, user} =
        Users.create(%{
          username: "user",
          email: "user@example.com",
          password: "password",
          password_confirmation: "password"
        })

      assert user.username == "user"
      assert user.email == "user@example.com"
    end

    test "uploading an avatar" do
      {:ok, user} =
        Users.create(%{
          username: "user",
          email: "user@example.com",
          password: "password",
          password_confirmation: "password",
          avatar: %{path: "test/fixtures/avatar.png", filename: "avatar.png"}
        })

      assert user.avatar_key
      assert user.avatar_extension == ".png"
    end
  end

  describe "updating users" do
    test "changing email triggers verification" do
      {:ok, user} = TestHelpers.create_user()
      {:ok, user} = Users.verify_email(user.email_verification_token)

      {:ok, user} =
        Users.update(user, %{
          email: "new@example.com"
        })

      assert user.email == "new@example.com"
      assert user.email_verification_token
      refute user.email_verified_at
    end

    test "uploading an avatar" do
      {:ok, user} = TestHelpers.create_user()
      {:ok, user} = Users.verify_email(user.email_verification_token)

      {:ok, user} =
        Users.update(user, %{
          avatar: %{path: "test/fixtures/avatar.png", filename: "avatar.png"}
        })

      assert user.avatar_key
      assert user.avatar_extension == ".png"
    end
  end

  describe "changing the password" do
    test "correct current password" do
      {:ok, user} = TestHelpers.create_user(%{password: "password"})

      {:ok, user} =
        Users.change_password(user, "password", %{
          password: "p@ssw0rd",
          password_confirmation: "p@ssw0rd"
        })

      assert {:ok, _user} = Users.validate_login(user.email, "p@ssw0rd")
    end

    test "invalid current password" do
      {:ok, user} = TestHelpers.create_user(%{password: "password"})

      {:error, :invalid} =
        Users.change_password(user, "p2ssword", %{
          password: "p@ssw0rd",
          password_confirmation: "p@ssw0rd"
        })
    end

    test "invalid new passwords" do
      {:ok, user} = TestHelpers.create_user(%{password: "password"})

      {:error, _changeset} =
        Users.change_password(user, "password", %{
          password: "p@ssw0rd",
          password_confirmation: "p@ssw0r"
        })
    end
  end

  describe "password resets" do
    test "starting a password reset" do
      {:ok, user} = TestHelpers.create_user(%{email: "user@example.com"})

      :ok = Users.start_password_reset(user.email)

      assert_email_delivered_with(to: [nil: "user@example.com"])
    end
  end
end
