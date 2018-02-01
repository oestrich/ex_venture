defmodule Web.UserTest do
  use Data.ModelCase

  alias Data.QuestProgress
  alias Game.Account
  alias Game.Authentication
  alias Game.Session
  alias Web.Room
  alias Web.User
  alias Web.Zone

  setup do
    user = create_user(%{name: "user", password: "password", flags: ["admin"]})
    %{user: user}
  end

  describe "teleporting players" do
    setup do
      {:ok, zone} = Zone.create(zone_attributes(%{name: "The Forest"}))
      {:ok, room} = Room.create(zone, room_attributes(%{}))

      %{room: room}
    end

    test "teleporting a player", %{user: user, room: room} do
      Session.Registry.register(user)

      {:ok, user} = User.teleport(user, room.id |> Integer.to_string())

      room_id = room.id

      assert user.save.room_id == room_id
      assert_receive {:"$gen_cast", {:teleport, ^room_id}}

      Game.Room._get_state(room.id)
    end

    test "teleporting a player - only updates if player not in the game", %{user: user, room: room} do
      {:ok, user} = User.teleport(user, room.id |> Integer.to_string())

      room_id = room.id

      assert user.save.room_id == room_id
      refute_receive {:"$gen_cast", {:teleport, ^room_id}}
    end
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
