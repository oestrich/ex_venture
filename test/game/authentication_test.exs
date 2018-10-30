defmodule Game.AuthenticationTest do
  use Data.ModelCase

  alias Game.Authentication

  setup do
    fighter = create_class()
    user = create_user(%{name: "user", password: "password"})
    character = create_character(user, %{name: "user", class_id: fighter.id})
    %{character: character}
  end

  test "ensures stats are defaulted", %{character: character} do
    {:ok, character} = character |> Ecto.Changeset.change(%{save: %{character.save | stats: %{}}}) |> Repo.update

    character = Authentication.find_character(character.id)

    assert character.save.stats.endurance_points == 20
    assert character.save.stats.max_endurance_points == 20
  end
end
