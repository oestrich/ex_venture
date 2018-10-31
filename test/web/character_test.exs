defmodule Web.CharacterTest do
  use Data.ModelCase

  alias Data.QuestProgress
  alias Game.Account
  alias Game.Session
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

  describe "reset a user" do
    setup [:with_character, :with_config]

    test "resets the save", %{character: character} do
      save = %{character.save | level: 2}
      {:ok, character} = Account.save(character, save)

      :ok = Character.reset(character.id)

      character = Data.Repo.get(Data.Character, character.id)
      assert character.save.level == 1
    end

    test "resets quests", %{character: character} do
      guard = create_npc(%{is_quest_giver: true})
      quest = create_quest(guard)

      create_quest_progress(character, quest)

      :ok = Character.reset(character.id)

      assert Data.Repo.all(QuestProgress) == []
    end
  end

  def with_user(_) do
    %{user: create_user(%{name: "user", password: "password"})}
  end

  def with_character(%{user: user}) do
    %{character: create_character(user, %{name: "user"})}
  end

  def with_config(_) do
    create_config(:starting_save, base_save() |> Poison.encode!)
    :ok
  end
end
