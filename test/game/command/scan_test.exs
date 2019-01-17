defmodule Game.Command.ScanTest do
  use ExVenture.CommandCase

  alias Game.Command.Scan
  alias Game.Door

  doctest Scan

  setup do
    user = create_user(%{name: "user", password: "password"})
    character = create_character(user)

    state = session_state(%{
      user: user,
      character: character,
      save: character.save
    })

    %{state: state}
  end

  describe "look at the rooms around you" do
    setup do
      north_exit = %{id: 4, has_door: true, door_id: 4, direction: "north", start_id: 1, finish_id: 2}
      in_exit = %{id: 5, has_door: true, door_id: 5, direction: "in", start_id: 1, finish_id: 3}

      Door.set(north_exit, "open")
      Door.set(in_exit, "closed")

      start_room(%{
        id: 1,
        exits: [north_exit, in_exit],
        npcs: [%{id: 1, name: "Bandit"}],
      })
      start_room(%{
        id: 2,
        players: [%{id: 1, name: "Player"}],
      })
      start_room(%{
        id: 3,
        npcs: [%{id: 1, name: "Guard"}],
      })

      :ok
    end

    test "sees what is in your current room", %{state: state} do
      :ok = Scan.run({}, state)

      assert_socket_echo "bandit"
    end

    test "sees what is in rooms next to you", %{state: state} do
      :ok = Scan.run({}, state)

      assert_socket_echo "player"
    end

    test "doors block sight", %{state: state} do
      :ok = Scan.run({}, state)

      refute_socket_echo "guard"
    end
  end
end
