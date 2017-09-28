defmodule Game.Command.RunTest do
  use Data.ModelCase
  doctest Game.Command.Run

  alias Game.Command

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    {:ok, %{session: :session, socket: :socket}}
  end

  test "run in a set of directions", %{session: session, socket: socket} do
    user = %{id: 10, save: %{room_id: 1}}
    state = %{socket: socket, user: user, save: user.save}
    @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 2, south_id: 1}], players: [], shops: []})

    {:update, state, continue_command} = Command.Run.run({"nen"}, session, state)

    assert state.save.room_id == 2
    assert continue_command == {Game.Command.Run, {[:east, :north]}, 10}
  end

  test "continue running in the processed set of directions", %{session: session, socket: socket} do
    user = %{id: 10, save: %{room_id: 1}}
    state = %{socket: socket, user: user, save: user.save}
    @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 2, south_id: 1}], players: [], shops: []})

    {:update, state, continue_command} = Command.Run.run({[:north, :east]}, session, state)

    assert state.save.room_id == 2
    assert continue_command == {Game.Command.Run, {[:east]}, 10}
  end

  test "end of the run", %{session: session, socket: socket} do
    user = %{id: 10, save: %{room_id: 1}}
    state = %{socket: socket, user: user, save: user.save}
    @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 2, south_id: 1}], players: [], shops: []})

    {:update, state} = Command.Run.run({[:north]}, session, state)

    assert state.save.room_id == 2
  end

  test "failure to move in a direction stops the run", %{session: session, socket: socket} do
    user = %{id: 10, save: %{room_id: 1}}
    state = %{socket: socket, user: user, save: user.save}
    @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 2, south_id: 1}], players: [], shops: []})

    :ok = Command.Run.run({[:east, :north]}, session, state)

    assert @socket.get_echos() == [{:socket, "Could not move east, no exit found."}]
  end

  describe "parsing run directions" do
    test "expand directions" do
      assert Command.Run.parse_run("2en3s") == [:east, :east, :north, :south, :south, :south]
    end

    test "handles bad input" do
      assert Command.Run.parse_run("2ed3s") == [:east, :east, :south, :south, :south]
    end
  end
end
