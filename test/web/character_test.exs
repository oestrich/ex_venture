defmodule Web.CharacterTest do
  use Data.ModelCase

  alias Web.Character
  alias Game.Session

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

  describe "disconnecting players" do
    setup [:with_character]

    test "disconnecting connected players", %{character: character} do
      Session.Registry.register(character)
      Session.Registry.catch_up()

      Character.disconnect()

      assert_receive {:"$gen_cast", {:disconnect, [reason: "server shutdown", force: true]}}
    end

    test "disconnecting a single player", %{character: character} do
      Session.Registry.register(character)
      Session.Registry.catch_up()

      Character.disconnect(character.id)

      assert_receive {:"$gen_cast", {:disconnect, [reason: "disconnect", force: true]}}
    end
  end

  def with_user(_) do
    %{user: create_user(%{name: "user", password: "password"})}
  end

  def with_character(%{user: user}) do
    %{character: create_character(user, %{name: "user"})}
  end
end
