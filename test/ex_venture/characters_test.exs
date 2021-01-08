defmodule ExVenture.CharactersTest do
  use ExVenture.DataCase

  alias ExVenture.Characters

  describe "creating characters" do
    test "successfully" do
      {:ok, user} = TestHelpers.create_user()

      {:ok, character} = Characters.create(user, %{name: "Player"})

      assert character.name == "Player"
    end

    test "failure" do
      {:ok, user} = TestHelpers.create_user()

      {:error, changeset} = Characters.create(user, %{})

      assert changeset.errors[:name]
    end
  end

  describe "updating characters" do
    test "successfully" do
      {:ok, user} = TestHelpers.create_user()

      {:ok, character} = Characters.create(user, %{name: "Player"})
      {:ok, character} = Characters.update(character, %{name: "Updated"})

      assert character.name == "Updated"
    end

    test "failure" do
      {:ok, user} = TestHelpers.create_user()

      {:ok, character} = Characters.create(user, %{name: "Player"})
      {:error, changeset} = Characters.update(character, %{name: nil})

      assert changeset.errors[:name]
    end
  end
end
