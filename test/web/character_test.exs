defmodule Web.CharacterTest do
  use Data.ModelCase

  alias Web.Character

  setup [:with_user]

  describe "creating a character" do
    setup do
      create_config(:starting_save, base_save() |> Poison.encode!)
      class = create_class()
      race = create_race()

      %{race: race, class: class}
    end

    test "create a new player", %{user: user, race: race, class: class} do
      {:ok, character} = Character.create(user, %{
        "name" => "player",
        "class_id" => class.id,
        "race_id" => race.id,
      })

      assert character.save
      assert character.name == "player"
      assert character.race_id
      assert character.class_id
    end
  end

  def with_user(_) do
    %{user: create_user(%{name: "user", password: "password"})}
  end
end
