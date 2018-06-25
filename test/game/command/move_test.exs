defmodule Game.Command.MoveTest do
  use Data.ModelCase

  @socket Test.Networking.Socket
  @room Test.Game.Room

  alias Game.Command
  alias Game.Command.Move
  alias Game.Door
  alias Game.Session.Registry
  alias Game.Session.State

  @basic_room %Game.Environment.State.Room{
    id: 1,
    name: "",
    description: "",
    players: [],
    shops: [],
    zone: %{id: 1, name: ""}
  }

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
      skills: %{}
    }

    %{socket: socket, user: user, state: state}
  end

  describe "moving in a direction" do
    setup do
      %{room_exit: %{id: 1, direction: "north", start_id: 1, finish_id: 2, has_door: false, door_id: nil}}
    end

    test "north", %{state: state, room_exit: room_exit} do
      @room.set_room(%{@basic_room | exits: [room_exit]})
      command = %Command{module: Command.Move, args: {:move, "north"}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))
      assert state.save.room_id == 2
    end

    test "north - not found", %{state: state} do
      @room.set_room(%{@basic_room | exits: []})
      command = %Command{module: Command.Move, args: {:move, "north"}}
      {:error, :no_exit} = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "north - door is closed", %{state: state, room_exit: room_exit} do
      room_exit = %{room_exit | has_door: true, door_id: "uuid"}
      @room.set_room(%{@basic_room | exits: [room_exit]})
      Door.load(room_exit)
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:move, "north"}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      assert state.save.room_id == 2

      socket = state.socket
      [{^socket, "You opened the door."}, {^socket, _}] = @socket.get_echos()
    end

    test "north - door is open", %{state: state, room_exit: room_exit} do
      room_exit = %{room_exit | has_door: true, door_id: "uuid"}
      @room.set_room(%{@basic_room | exits: [room_exit]})
      Door.load(room_exit)
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:move, "north"}}
      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      assert state.save.room_id == 2
    end
  end

  test "clears the target after moving", %{socket: socket, state: state, user: user} do
    @room.set_room(%{@basic_room | exits: [%{direction: "north", start_id: 1, finish_id: 2}]})
    Registry.register(user)

    state = Map.merge(state, %{user: user, save: %{room_id: 1}, target: {:user, 10}})
    command = %Command{module: Command.Move, args: {:move, "north"}}
    {:update, state} = Command.run(command, state)

    assert state.target == nil
    assert [{^socket, "Target.Clear", "{}"} | _] = @socket.get_push_gmcps()

    Registry.unregister()
  end

  describe "open a door" do
    setup do
      room_exit = %{id: 10, has_door: true, door_id: 10, direction: "north", start_id: 1, finish_id: 2}
      @room.set_room(%Game.Environment.State.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})
      Door.load(room_exit)
      Door.set(room_exit, "closed")
      %{room_exit: room_exit}
    end

    test "open the door", %{socket: socket, state: state} do
      command = %Command{module: Command.Move, args: {:open, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r(opened the door), echo)

      [{^socket, "Zone.Map", _gmcp}] = @socket.get_push_gmcps()
    end

    test "a door does not exist in the direction", %{socket: socket, state: state} do
      room_exit = %{id: 10, direction: "north", start_id: 1, finish_id: 2, has_door: false}
      @room.set_room(%Game.Environment.State.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:open, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no door)i, error)
    end

    test "an exit does not exist in the direction", %{socket: socket, state: state} do
      @room.set_room(%Game.Environment.State.Room{id: 1, name: "", description: "", exits: [], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:open, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no exit)i, error)
    end

    test "door already open", %{socket: socket, state: state, room_exit: room_exit} do
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:open, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(door was already open), error)
    end
  end

  describe "close a door" do
    setup do
      room_exit = %{id: 10, has_door: true, door_id: 10, direction: "north", start_id: 1, finish_id: 2}
      @room.set_room(%Game.Environment.State.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})
      Door.load(room_exit)
      Door.set(room_exit, "open")
      %{room_exit: room_exit}
    end

    test "close the door", %{socket: socket, state: state} do
      command = %Command{module: Command.Move, args: {:close, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r(closed the door), echo)

      [{^socket, "Zone.Map", _gmcp}] = @socket.get_push_gmcps()
    end

    test "a door does not exist in the direction", %{socket: socket, state: state} do
      room_exit = %{id: 10, direction: "north", start_id: 1, finish_id: 2, has_door: false}
      @room.set_room(%Game.Environment.State.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:close, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no door)i, error)
    end

    test "an exit does not exist in the direction", %{socket: socket, state: state} do
      @room.set_room(%Game.Environment.State.Room{id: 1, name: "", description: "", exits: [], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:close, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(no exit)i, error)
    end

    test "door already closed", %{socket: socket, state: state, room_exit: room_exit} do
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:close, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      [{^socket, error}] = @socket.get_echos()
      assert Regex.match?(~r(door was already closed), error)
    end
  end

  describe "cannot leave with a cooldown active" do
    test "you're stuck", %{state: state} do
      room_exit = %{id: 10, direction: "north", start_id: 1, finish_id: 2, has_door: false}
      @room.set_room(%{@basic_room | exits: [room_exit]})

      state = Map.merge(state, %{
        skills: %{10 => Timex.now() |> Timex.shift(seconds: 3)},
        save: %{room_id: 1}
      })

      :ok = Move.run({:move, "north"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r(cannot move)i, echo)
    end
  end
end
