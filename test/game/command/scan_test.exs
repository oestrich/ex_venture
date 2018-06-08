defmodule Game.Command.ScanTest do
  use Data.ModelCase
  doctest Game.Command.Scan

  alias Game.Command.Scan
  alias Game.Door
  alias Game.Session.State

  @socket Test.Networking.Socket
  @room Test.Game.Room

  @basic_room %Game.Environment.State.Room{
    name: "Room",
    players: [],
    npcs: []
  }

  setup do
    @socket.clear_messages()

    user = create_user(%{name: "user", password: "password"})

    state = %State{
      socket: :socket,
      state: "active",
      mode: "commands",
      user: user,
      save: user.save
    }

    %{state: state}
  end

  describe "look at the rooms around you" do
    setup do
      north_exit = %{id: 4, direction: "north", start_id: 1, finish_id: 2}
      in_exit = %{id: 5, direction: "in", start_id: 1, finish_id: 3}

      room =
        Map.merge(@basic_room, %{
          id: 1,
          exits: [north_exit, in_exit],
          npcs: [%{id: 1, name: "Bandit"}],
        })

      Door.set(north_exit, "open")
      Door.set(in_exit, "closed")

      @room.set_room(room, multiple: true)

      @room.set_room(Map.merge(@basic_room, %{
        id: 2,
        players: [%{id: 1, name: "Player"}],
      }), multiple: true)
      @room.set_room(Map.merge(@basic_room, %{
        id: 3,
        npcs: [%{id: 1, name: "Guard"}],
      }), multiple: true)

      :ok
    end

    test "sees what is in your current room", %{state: state} do
      :ok = Scan.run({}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/Bandit/, echo)
    end

    test "sees what is in rooms next to you", %{state: state} do
      :ok = Scan.run({}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/Player/, echo)
    end

    test "doors block sight", %{state: state} do
      :ok = Scan.run({}, state)

      [{_socket, echo}] = @socket.get_echos()
      refute Regex.match?(~r/Guard/, echo)
    end
  end
end
