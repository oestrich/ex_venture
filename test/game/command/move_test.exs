defmodule Game.Command.MoveTest do
  use Data.ModelCase

  @socket Test.Networking.Socket
  @room Test.Game.Room

  alias Game.Command
  alias Game.Door
  alias Game.Session.Registry

  setup do
    @socket.clear_messages
    start_and_clear_doors()

    socket = :socket
    user = %{id: 10}
    state = %{
      socket: socket,
      user: user,
    }

    %{session: :session, socket: socket, user: user, state: state}
  end

  describe "north" do
    test "north", %{session: session, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 2, south_id: 1}], players: [], shops: []})
      command = %Command{module: Command.Move, args: {:north}}
      {:update, state} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))
      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end

    test "north - not found", %{session: session, state: state} do
      @room.set_room(%Data.Room{exits: []})
      command = %Command{module: Command.Move, args: {:north}}
      {:error, :no_exit} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "north - not enough movement", %{session: session, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 2, south_id: 1}], players: [], shops: []})
      command = %Command{module: Command.Move, args: {:north}}
      {:error, :no_movement} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 0}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no movement), error)
    end

    test "north - door is closed", %{session: session, state: state} do
      room_exit = %{id: 10, north_id: 2, south_id: 1, has_door: true}
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})
      Door.load(room_exit)
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:north}}
      {:error, :door_closed} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(door is closed), error)
    end

    test "north - door is open", %{session: session, state: state} do
      room_exit = %{id: 10, north_id: 2, south_id: 1, has_door: true}
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})
      Door.load(room_exit)
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:north}}
      {:update, state} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end
  end

  describe "east" do
    test "east", %{session: session, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{west_id: 1, east_id: 2}], players: [], shops: []})
      command = %Command{module: Command.Move, args: {:east}}
      {:update, state} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))
      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end

    test "east - not found", %{session: session, state: state} do
      @room.set_room(%Data.Room{exits: []})
      command = %Command{module: Command.Move, args: {:east}}
      {:error, :no_exit} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "east - not enough movement", %{session: session, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{west_id: 1, east_id: 2}], players: [], shops: []})
      command = %Command{module: Command.Move, args: {:east}}
      {:error, :no_movement} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 0}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no movement), error)
    end

    test "east - door is closed", %{session: session, state: state} do
      room_exit = %{id: 10, west_id: 1, east_id: 2, has_door: true}
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})
      Door.load(room_exit)
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:east}}
      {:error, :door_closed} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(door is closed), error)
    end

    test "east - door is open", %{session: session, state: state} do
      room_exit = %{id: 10, east_id: 2, west_id: 1, has_door: true}
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})
      Door.load(room_exit)
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:east}}
      {:update, state} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end
  end

  describe "south" do
    test "south", %{session: session, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 1, south_id: 2}], players: [], shops: []})
      command = %Command{module: Command.Move, args: {:south}}
      {:update, state} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))
      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end

    test "south - not found", %{session: session, state: state} do
      @room.set_room(%Data.Room{exits: []})
      command = %Command{module: Command.Move, args: {:south}}
      {:error, :no_exit} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "south - not enough movement", %{session: session, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 1, south_id: 2}], players: [], shops: []})
      command = %Command{module: Command.Move, args: {:south}}
      {:error, :no_movement} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 0}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no movement), error)
    end

    test "south - door is closed", %{session: session, state: state} do
      room_exit = %{id: 10, north_id: 1, south_id: 2, has_door: true}
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})
      Door.load(room_exit)
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:south}}
      {:error, :door_closed} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(door is closed), error)
    end

    test "south - door is open", %{session: session, state: state} do
      room_exit = %{id: 10, south_id: 2, north_id: 1, has_door: true}
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})
      Door.load(room_exit)
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:south}}
      {:update, state} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end
  end

  describe "west" do
    test "west", %{session: session, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{west_id: 2, east_id: 1}], players: [], shops: []})
      command = %Command{module: Command.Move, args: {:west}}
      {:update, state} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))
      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end

    test "west - not found", %{session: session, state: state} do
      @room.set_room(%Data.Room{exits: []})
      command = %Command{module: Command.Move, args: {:west}}
      {:error, :no_exit} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "west - not enough movement", %{session: session, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{west_id: 2, east_id: 1}], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:west}}
      {:error, :no_movement} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 0}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no movement), error)
    end

    test "west - door is closed", %{session: session, state: state} do
      room_exit = %{id: 10, east_id: 1, west_id: 2, has_door: true}
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})
      Door.load(room_exit)
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:west}}
      {:error, :door_closed} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(door is closed), error)
    end

    test "west - door is open", %{session: session, state: state} do
      room_exit = %{id: 10, west_id: 2, east_id: 1, has_door: true}
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})
      Door.load(room_exit)
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:west}}
      {:update, state} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end
  end

  describe "up" do
    test "up", %{session: session, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{up_id: 2, down_id: 1}], players: [], shops: []})
      command = %Command{module: Command.Move, args: {:up}}
      {:update, state} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))
      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end

    test "up - not found", %{session: session, state: state} do
      @room.set_room(%Data.Room{exits: []})
      command = %Command{module: Command.Move, args: {:up}}
      {:error, :no_exit} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "up - not enough movement", %{session: session, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{up_id: 2, down_id: 1}], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:up}}
      {:error, :no_movement} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 0}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no movement), error)
    end

    test "up - door is closed", %{session: session, state: state} do
      room_exit = %{id: 10, down_id: 1, up_id: 2, has_door: true}
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})
      Door.load(room_exit)
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:up}}
      {:error, :door_closed} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(door is closed), error)
    end

    test "up - door is open", %{session: session, state: state} do
      room_exit = %{id: 10, up_id: 2, down_id: 1, has_door: true}
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})
      Door.load(room_exit)
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:up}}
      {:update, state} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end
  end

  describe "down" do
    test "down", %{session: session, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{down_id: 2, up_id: 1}], players: [], shops: []})
      command = %Command{module: Command.Move, args: {:down}}
      {:update, state} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))
      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end

    test "down - not found", %{session: session, state: state} do
      @room.set_room(%Data.Room{exits: []})
      command = %Command{module: Command.Move, args: {:down}}
      {:error, :no_exit} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "down - not enough movement", %{session: session, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{down_id: 2, up_id: 1}], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:down}}
      {:error, :no_movement} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 0}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no movement), error)
    end

    test "down - door is closed", %{session: session, state: state} do
      room_exit = %{id: 10, up_id: 1, down_id: 2, has_door: true}
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})
      Door.load(room_exit)
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:down}}
      {:error, :door_closed} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(door is closed), error)
    end

    test "down - door is open", %{session: session, state: state} do
      room_exit = %{id: 10, down_id: 2, up_id: 1, has_door: true}
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})
      Door.load(room_exit)
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:down}}
      {:update, state} = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end
  end

  test "clears the target after moving", %{session: session, socket: socket, state: state, user: user} do
    @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 2, south_id: 1}], players: [], shops: []})
    Registry.register(user)

    state = Map.merge(state, %{user: user, save: %{room_id: 1, stats: %{move_points: 10}}, target: {:user, 10}})
    command = %Command{module: Command.Move, args: {:north}}
    {:update, state} = Command.run(command, session, state)

    assert state.target == nil
    assert_received {:"$gen_cast", {:remove_target, {:user, ^user}}}
    assert [{^socket, "Target.Clear", "{}"} | _] = @socket.get_push_gmcps()

    Registry.unregister()
  end

  describe "open a door" do
    setup do
      room_exit = %{id: 10, south_id: 1, north_id: 2, has_door: true}
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})
      Door.load(room_exit)
      Door.set(room_exit, "closed")
      %{room_exit: room_exit}
    end

    test "open the door", %{session: session, socket: socket, state: state} do
      command = %Command{module: Command.Move, args: {:open, :north}}
      :ok = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r(opened the door), echo)
    end

    test "a door does not exist in the direction", %{session: session, socket: socket, state: state} do
      room_exit = %{id: 10, north_id: 2, south_id: 1, has_door: false}
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:open, :north}}
      :ok = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no door)i, error)
    end

    test "an exit does not exist in the direction", %{session: session, socket: socket, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:open, :north}}
      :ok = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no exit)i, error)
    end

    test "door already open", %{session: session, socket: socket, state: state, room_exit: room_exit} do
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:open, :north}}
      :ok = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(door was already open), error)
    end
  end

  describe "close a door" do
    setup do
      room_exit = %{id: 10, south_id: 1, north_id: 2, has_door: true}
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})
      Door.load(room_exit)
      Door.set(room_exit, "open")
      %{room_exit: room_exit}
    end

    test "close the door", %{session: session, socket: socket, state: state} do
      command = %Command{module: Command.Move, args: {:close, :north}}
      :ok = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r(closed the door), echo)
    end

    test "a door does not exist in the direction", %{session: session, socket: socket, state: state} do
      room_exit = %{id: 10, north_id: 2, south_id: 1, has_door: false}
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:close, :north}}
      :ok = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no door)i, error)
    end

    test "an exit does not exist in the direction", %{session: session, socket: socket, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:close, :north}}
      :ok = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no exit)i, error)
    end

    test "door already closed", %{session: session, socket: socket, state: state, room_exit: room_exit} do
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:close, :north}}
      :ok = Command.run(command, session, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(door was already closed), error)
    end
  end
end
