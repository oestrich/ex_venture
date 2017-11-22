defmodule Game.Command.RunTest do
  use Data.ModelCase
  doctest Game.Command.Run

  alias Game.Command

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    user = %{id: 10, class: %{points_abbreviation: "SP"}, save: %{room_id: 1, stats: %{move_points: 10}}}
    state = %{socket: :socket, user: user, save: user.save}
    {:ok, %{session: :session, socket: :socket, state: state}}
  end

  test "run in a set of directions", %{session: session, state: state} do
    @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 2, south_id: 1}], players: [], shops: []})

    {:update, state, continue_command} = Command.Run.run({"nen"}, session, state)

    assert state.save.room_id == 2
    assert continue_command == {%Command{module: Command.Run, args: {[:east, :north]}, continue: true}, 10}
  end

  test "continue running in the processed set of directions", %{session: session, state: state} do
    @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 2, south_id: 1}], players: [], shops: []})

    {:update, state, continue_command} = Command.Run.run({[:north, :east]}, session, state)

    assert state.save.room_id == 2
    assert continue_command == {%Command{module: Command.Run, args: {[:east]}, continue: true}, 10}
  end

  test "end of the run", %{session: session, state: state} do
    @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 2, south_id: 1}], players: [], shops: []})

    {:update, state} = Command.Run.run({[:north]}, session, state)

    assert state.save.room_id == 2
  end

  test "failure to move in a direction stops the run", %{session: session, state: state} do
    @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 2, south_id: 1}], players: [], shops: []})

    :ok = Command.Run.run({[:east, :north]}, session, state)

    assert @socket.get_echos() == [{:socket, "Could not move east, no exit found."}]
  end

  test "out of movement stops the run", %{session: session, state: state} do
    state = put_in(state[:save][:stats][:move_points], 0)
    @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 2, south_id: 1}], players: [], shops: []})

    :ok = Command.Run.run({[:north, :east]}, session, state)

    [{:socket, error}] = @socket.get_echos()
    assert Regex.match?(~r(no movement), error)
  end

  describe "parsing run directions" do
    test "expand directions" do
      assert Command.Run.parse_run("2en3s") == [:east, :east, :north, :south, :south, :south]
    end

    test "handles bad input" do
      assert Command.Run.parse_run("2ed3s") == [:east, :east, :south, :south, :south]
    end

    test "handles no directions" do
      assert Command.Run.parse_run("") == []
    end
  end
end
