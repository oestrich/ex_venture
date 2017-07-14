defmodule Game.AuthenticationTest do
  use Data.ModelCase

  alias Game.Authentication

  setup do
    user = create_user(%{username: "user", password: "password"})
    {:ok, %{user: user}}
  end

  test "finds and validates a user", %{user: user} do
    assert Authentication.find_and_validate("user", "password").id == user.id
  end

  test "password is wrong" do
    assert Authentication.find_and_validate("user", "p@ssword") == {:error, :invalid}
  end

  test "username is wrong" do
    assert Authentication.find_and_validate("user", "p@ssword") == {:error, :invalid}
  end
end
