defmodule Game.Command.RunTest do
  use Data.ModelCase
  doctest Game.Command.Run

  alias Game.Command
  alias Game.Session

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    user = %{id: 10, save: %{room_id: 1, stats: %{move_points: 10}}}

    room = %Game.Environment.State{
      id: 1,
      name: "",
      description: "",
      exits: [%{direction: "north", start_id: 1, finish_id: 2}],
      players: [],
      shops: [],
      zone: %{id: 10, name: "Zone"}
    }
    @room.set_room(room)

    state = %Session.State{
      state: "active",
      mode: "command",
      socket: :socket,
      user: user,
      save: user.save,
      skills: %{}
    }

    {:ok, %{socket: :socket, state: state}}
  end

  test "run in a set of directions", %{state: state} do
    {:update, state, continue_command} = Command.Run.run({"nen"}, state)

    assert state.save.room_id == 2
    assert continue_command == {%Command{module: Command.Run, args: {[:east, :north]}, continue: true}, 10}
  end

  test "continue running in the processed set of directions", %{state: state} do
    {:update, state, continue_command} = Command.Run.run({[:north, :east]}, state)

    assert state.save.room_id == 2
    assert continue_command == {%Command{module: Command.Run, args: {[:east]}, continue: true}, 10}
  end

  test "end of the run", %{state: state} do
    {:update, state} = Command.Run.run({[:north]}, state)

    assert state.save.room_id == 2
  end

  test "failure to move in a direction stops the run", %{state: state} do
    :ok = Command.Run.run({[:east, :north]}, state)

    assert @socket.get_echos() == [{:socket, "Could not move east, no exit found."}]
  end

  test "out of movement stops the run", %{state: state} do
    state = %{state | save: %{state.save | stats: %{state.save.stats | move_points: 0}}}

    :ok = Command.Run.run({[:north, :east]}, state)

    [{:socket, error}] = @socket.get_echos()
    assert Regex.match?(~r(no movement), error)
  end

  describe "parsing run directions" do
    test "expand directions" do
      assert Command.Run.parse_run("2en3s1u2d") == [:east, :east, :north, :south, :south, :south, :up, :down, :down]
    end

    test "handles bad input" do
      assert Command.Run.parse_run("2ef3s") == [:east, :east, :south, :south, :south]
    end

    test "handles no directions" do
      assert Command.Run.parse_run("") == []
    end
  end
end
