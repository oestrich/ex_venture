defmodule Game.Command.MoveTest do
  use Data.ModelCase

  @socket Test.Networking.Socket
  @room Test.Game.Room

  alias Game.Command
  alias Game.Door
  alias Game.Session.Registry
  alias Game.Session.State

  @basic_room %Data.Room{id: 1, name: "", description: "", players: [], shops: [], zone: %{id: 1, name: ""}}

  setup do
    @socket.clear_messages
    start_and_clear_doors()

    socket = :socket
    user = %{id: 10}
    state = %State{
      state: "active",
      mode: "command",
      socket: socket,
      user: user,
    }

    %{socket: socket, user: user, state: state}
  end

  describe "north" do
    test "north", %{state: state} do
      @room.set_room(%{@basic_room | exits: [%{north_id: 2, south_id: 1}]})
      command = %Command{module: Command.Move, args: {:north}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))
      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end

    test "north - not found", %{state: state} do
      @room.set_room(%Data.Room{exits: []})
      command = %Command{module: Command.Move, args: {:north}}
      {:error, :no_exit} = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "north - not enough movement", %{state: state} do
      @room.set_room(%{@basic_room | exits: [%{north_id: 2, south_id: 1}]})
      command = %Command{module: Command.Move, args: {:north}}
      {:error, :no_movement} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 0}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no movement), error)
    end

    test "north - door is closed", %{state: state} do
      room_exit = %{id: 10, north_id: 2, south_id: 1, has_door: true}
      @room.set_room(%{@basic_room | exits: [room_exit]})
      Door.load(room_exit)
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:north}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9

      socket = state.socket
      [{^socket, "You opened the door."}, {^socket, _}] = @socket.get_echos()
    end

    test "north - door is open", %{state: state} do
      room_exit = %{id: 10, north_id: 2, south_id: 1, has_door: true}
      @room.set_room(%{@basic_room | exits: [room_exit]})
      Door.load(room_exit)
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:north}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end
  end

  describe "east" do
    test "east", %{state: state} do
      @room.set_room(%{@basic_room | exits: [%{west_id: 1, east_id: 2}]})
      command = %Command{module: Command.Move, args: {:east}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))
      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end

    test "east - not found", %{state: state} do
      @room.set_room(%Data.Room{exits: []})
      command = %Command{module: Command.Move, args: {:east}}
      {:error, :no_exit} = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "east - not enough movement", %{state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{west_id: 1, east_id: 2}], players: [], shops: []})
      command = %Command{module: Command.Move, args: {:east}}
      {:error, :no_movement} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 0}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no movement), error)
    end

    test "east - door is closed", %{state: state} do
      room_exit = %{id: 10, west_id: 1, east_id: 2, has_door: true}
      @room.set_room(%{@basic_room | exits: [room_exit]})
      Door.load(room_exit)
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:east}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9

      socket = state.socket
      [{^socket, "You opened the door."}, {^socket, _}] = @socket.get_echos()
    end

    test "east - door is open", %{state: state} do
      room_exit = %{id: 10, east_id: 2, west_id: 1, has_door: true}
      @room.set_room(%{@basic_room | exits: [room_exit]})
      Door.load(room_exit)
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:east}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end
  end

  describe "south" do
    test "south", %{state: state} do
      @room.set_room(%{@basic_room | exits: [%{north_id: 1, south_id: 2}]})
      command = %Command{module: Command.Move, args: {:south}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))
      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end

    test "south - not found", %{state: state} do
      @room.set_room(%Data.Room{exits: []})
      command = %Command{module: Command.Move, args: {:south}}
      {:error, :no_exit} = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "south - not enough movement", %{state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 1, south_id: 2}], players: [], shops: []})
      command = %Command{module: Command.Move, args: {:south}}
      {:error, :no_movement} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 0}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no movement), error)
    end

    test "south - door is closed", %{state: state} do
      room_exit = %{id: 10, north_id: 1, south_id: 2, has_door: true}
      @room.set_room(%{@basic_room | exits: [room_exit]})
      Door.load(room_exit)
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:south}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9

      socket = state.socket
      [{^socket, "You opened the door."}, {^socket, _}] = @socket.get_echos()
    end

    test "south - door is open", %{state: state} do
      room_exit = %{id: 10, south_id: 2, north_id: 1, has_door: true}
      @room.set_room(%{@basic_room | exits: [room_exit]})
      Door.load(room_exit)
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:south}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end
  end

  describe "west" do
    test "west", %{state: state} do
      @room.set_room(%{@basic_room | exits: [%{west_id: 2, east_id: 1}]})
      command = %Command{module: Command.Move, args: {:west}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))
      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end

    test "west - not found", %{state: state} do
      @room.set_room(%Data.Room{exits: []})
      command = %Command{module: Command.Move, args: {:west}}
      {:error, :no_exit} = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "west - not enough movement", %{state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{west_id: 2, east_id: 1}], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:west}}
      {:error, :no_movement} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 0}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no movement), error)
    end

    test "west - door is closed", %{state: state} do
      room_exit = %{id: 10, east_id: 1, west_id: 2, has_door: true}
      @room.set_room(%{@basic_room | exits: [room_exit]})
      Door.load(room_exit)
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:west}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9

      socket = state.socket
      [{^socket, "You opened the door."}, {^socket, _}] = @socket.get_echos()
    end

    test "west - door is open", %{state: state} do
      room_exit = %{id: 10, west_id: 2, east_id: 1, has_door: true}
      @room.set_room(%{@basic_room | exits: [room_exit]})
      Door.load(room_exit)
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:west}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end
  end

  describe "up" do
    test "up", %{state: state} do
      @room.set_room(%{@basic_room | exits: [%{up_id: 2, down_id: 1}]})
      command = %Command{module: Command.Move, args: {:up}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))
      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end

    test "up - not found", %{state: state} do
      @room.set_room(%Data.Room{exits: []})
      command = %Command{module: Command.Move, args: {:up}}
      {:error, :no_exit} = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "up - not enough movement", %{state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{up_id: 2, down_id: 1}], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:up}}
      {:error, :no_movement} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 0}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no movement), error)
    end

    test "up - door is closed", %{state: state} do
      room_exit = %{id: 10, down_id: 1, up_id: 2, has_door: true}
      @room.set_room(%{@basic_room | exits: [room_exit]})
      Door.load(room_exit)
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:up}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9

      socket = state.socket
      [{^socket, "You opened the door."}, {^socket, _}] = @socket.get_echos()
    end

    test "up - door is open", %{state: state} do
      room_exit = %{id: 10, up_id: 2, down_id: 1, has_door: true}
      @room.set_room(%{@basic_room | exits: [room_exit]})
      Door.load(room_exit)
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:up}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end
  end

  describe "down" do
    test "down", %{state: state} do
      @room.set_room(%{@basic_room | exits: [%{down_id: 2, up_id: 1}]})
      command = %Command{module: Command.Move, args: {:down}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))
      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end

    test "down - not found", %{state: state} do
      @room.set_room(%Data.Room{exits: []})
      command = %Command{module: Command.Move, args: {:down}}
      {:error, :no_exit} = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "down - not enough movement", %{state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{down_id: 2, up_id: 1}], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:down}}
      {:error, :no_movement} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 0}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no movement), error)
    end

    test "down - door is closed", %{state: state} do
      room_exit = %{id: 10, up_id: 1, down_id: 2, has_door: true}
      @room.set_room(%{@basic_room | exits: [room_exit]})
      Door.load(room_exit)
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:down}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9

      socket = state.socket
      [{^socket, "You opened the door."}, {^socket, _}] = @socket.get_echos()
    end

    test "down - door is open", %{state: state} do
      room_exit = %{id: 10, down_id: 2, up_id: 1, has_door: true}
      @room.set_room(%{@basic_room | exits: [room_exit]})
      Door.load(room_exit)
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:down}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end
  end

  describe "in" do
    test "in", %{state: state} do
      @room.set_room(%{@basic_room | exits: [%{in_id: 2, out_id: 1}]})
      command = %Command{module: Command.Move, args: {:in}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))
      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end

    test "in - not found", %{state: state} do
      @room.set_room(%Data.Room{exits: []})
      command = %Command{module: Command.Move, args: {:in}}
      {:error, :no_exit} = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "in - not enough movement", %{state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{in_id: 2, out_id: 1}], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:in}}
      {:error, :no_movement} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 0}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no movement), error)
    end

    test "in - door is closed", %{state: state} do
      room_exit = %{id: 10, out_id: 1, in_id: 2, has_door: true}
      @room.set_room(%{@basic_room | exits: [room_exit]})
      Door.load(room_exit)
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:in}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9

      socket = state.socket
      [{^socket, "You opened the door."}, {^socket, _}] = @socket.get_echos()
    end

    test "in - door is open", %{state: state} do
      room_exit = %{id: 10, in_id: 2, out_id: 1, has_door: true}
      @room.set_room(%{@basic_room | exits: [room_exit]})
      Door.load(room_exit)
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:in}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end
  end

  describe "out" do
    test "out", %{state: state} do
      @room.set_room(%{@basic_room | exits: [%{out_id: 2, in_id: 1}]})
      command = %Command{module: Command.Move, args: {:out}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))
      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end

    test "out - not found", %{state: state} do
      @room.set_room(%Data.Room{exits: []})
      command = %Command{module: Command.Move, args: {:out}}
      {:error, :no_exit} = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "out - not enough movement", %{state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{out_id: 2, in_id: 1}], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:out}}
      {:error, :no_movement} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 0}}}))

      socket = state.socket
      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no movement), error)
    end

    test "out - door is closed", %{state: state} do
      room_exit = %{id: 10, in_id: 1, out_id: 2, has_door: true}
      @room.set_room(%{@basic_room | exits: [room_exit]})
      Door.load(room_exit)
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:out}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9

      socket = state.socket
      [{^socket, "You opened the door."}, {^socket, _}] = @socket.get_echos()
    end

    test "out - door is open", %{state: state} do
      room_exit = %{id: 10, out_id: 2, in_id: 1, has_door: true}
      @room.set_room(%{@basic_room | exits: [room_exit]})
      Door.load(room_exit)
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:out}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1, stats: %{move_points: 10}}}))

      assert state.save.room_id == 2
      assert state.save.stats.move_points == 9
    end
  end

  test "clears the target after moving", %{socket: socket, state: state, user: user} do
    @room.set_room(%{@basic_room | exits: [%{north_id: 2, south_id: 1}]})
    Registry.register(user)

    state = Map.merge(state, %{user: user, save: %{room_id: 1, stats: %{move_points: 10}}, target: {:user, 10}})
    command = %Command{module: Command.Move, args: {:north}}
    {:update, state} = Command.run(command, state)

    assert state.target == nil
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

    test "open the door", %{socket: socket, state: state} do
      command = %Command{module: Command.Move, args: {:open, :north}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r(opened the door), echo)

      [{^socket, "Zone.Map", _gmcp}] = @socket.get_push_gmcps()
    end

    test "a door does not exist in the direction", %{socket: socket, state: state} do
      room_exit = %{id: 10, north_id: 2, south_id: 1, has_door: false}
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:open, :north}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no door)i, error)
    end

    test "an exit does not exist in the direction", %{socket: socket, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:open, :north}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no exit)i, error)
    end

    test "door already open", %{socket: socket, state: state, room_exit: room_exit} do
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:open, :north}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

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

    test "close the door", %{socket: socket, state: state} do
      command = %Command{module: Command.Move, args: {:close, :north}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r(closed the door), echo)

      [{^socket, "Zone.Map", _gmcp}] = @socket.get_push_gmcps()
    end

    test "a door does not exist in the direction", %{socket: socket, state: state} do
      room_exit = %{id: 10, north_id: 2, south_id: 1, has_door: false}
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:close, :north}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no door)i, error)
    end

    test "an exit does not exist in the direction", %{socket: socket, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:close, :north}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no exit)i, error)
    end

    test "door already closed", %{socket: socket, state: state, room_exit: room_exit} do
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:close, :north}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(door was already closed), error)
    end
  end
end
