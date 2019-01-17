defmodule Game.Command.LookTest do
  use ExVenture.CommandCase

  alias Data.Exit
  alias Data.Item
  alias Game.Command.Look
  alias Game.Environment

  doctest Look

  describe "normal room" do
    setup do
      start_and_clear_items()
      item = create_item(%{name: "Short Sword", description: "A simple blade", keywords: ["sword"]})
      insert_item(item)

      bandit = %{
        id: 1,
        name: "Bandit",
        extra: %{
          original_id: 1,
          description: "bandit description",
          status_line: "[name] is here."
        },
      }

      room = %{
        items: [Item.instantiate(item)],
        npcs: [bandit],
        players: [%{id: 1, name: "Player"}],
        features: [%{key: "log", short_description: "log", description: "a log"}],
        zone: %{id: 10, name: "Zone"}
      }
      start_room(room)

      user = create_user(%{name: "hero", password: "password"})
      character = create_character(user, %{name: "hero"})
      %{state: session_state(%{user: user, character: character})}
    end

    test "view room information", %{state: state} do
      :ok = Look.run({}, state)

      assert_socket_echo ["hallway", "exits", "items"]
      assert_socket_gmcp {"Zone.Map", _}
    end

    test "view room information - the room is offline", %{state: state} do
      mark_room_offline()

      {:error, :room_offline} = Look.run({}, state)

      assert_socket_no_echo()
    end

    test "looking at an item", %{state: state} do
      :ok = Look.run({:other, "short sword"}, state)

      assert_socket_echo "a simple blade"
    end

    test "looking at an npc", %{state: state} do
      :ok = Look.run({:other, "bandit"}, state)

      assert_socket_echo "bandit description"
    end

    test "looking at a player", %{state: state} do
      :ok = Look.run({:other, "player"}, state)

      assert_socket_echo "player"
    end

    test "looking in a direction", %{state: state} do
      start_room(%{id: 2, name: "Hallway"})

      :ok = Look.run({:direction, "north"}, state)

      assert_socket_echo "hallway"
    end

    test "looking at a room feature", %{state: state} do
      :ok = Look.run({:other, "log"}, state)

      assert_socket_echo "a log"
    end

    test "could not find the name", %{state: state} do
      :ok = Look.run({:other, "unknown"}, state)

      assert_socket_echo "could not find"
    end
  end

  describe "overworld" do
    setup do
      room = %Environment.State.Overworld{
        id: "overworld:1:1,1",
        exits: [%Exit{has_door: false, direction: "west"}],
      }
      start_room(room)

      user = create_user(%{name: "hero", password: "password"})
      character = create_character(user, %{name: "hero"})
      save = %{character.save | room_id: "overworld:1:1,1"}
      %{state: session_state(%{user: user, character: character, save: save})}
    end

    test "looking in the overworld", %{state: state} do
      :ok = Look.run({}, state)

      assert_socket_echo "exits"
    end
  end
end
