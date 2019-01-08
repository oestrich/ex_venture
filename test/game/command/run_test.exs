defmodule Game.Command.RunTest do
  use Data.ModelCase

  doctest Game.Command.Run

  alias Data.Exit
  alias Game.Command

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    room = %Game.Environment.State.Room{
      id: 1,
      name: "",
      description: "",
      exits: [%Exit{has_door: false, direction: "north", start_id: 1, finish_id: 2}],
      players: [],
      shops: [],
      zone: %{id: 10, name: "Zone"}
    }
    @room.set_room(room)

    user = base_user()
    character = base_character(user)
    save = %{character.save | room_id: 1, experience_points: 10, stats: %{endurance_points: 10}}

    %{state: session_state(%{user: user, character: character, save: save, skills: %{}})}
  end

  test "run in a set of directions", %{state: state} do
    {:update, state, continue_command} = Command.Run.run({"1n1e1n"}, state)

    assert state.save.room_id == 2
    assert continue_command == {%Command{module: Command.Run, args: {["east", "north"]}, continue: true}, 10}
  end

  test "continue running in the processed set of directions", %{state: state} do
    {:update, state, continue_command} = Command.Run.run({["north", "east"]}, state)

    assert state.save.room_id == 2
    assert continue_command == {%Command{module: Command.Run, args: {["east"]}, continue: true}, 10}
  end

  test "end of the run", %{state: state} do
    {:update, state} = Command.Run.run({["north"]}, state)

    assert state.save.room_id == 2
  end

  test "failure to move in a direction stops the run", %{state: state} do
    :ok = Command.Run.run({["east", "north"]}, state)

    assert @socket.get_echos() == [{:socket, "Could not move east, no exit found."}]
  end

  describe "parsing run directions" do
    test "expand directions" do
      assert Command.Run.parse_run("2e1n3s1u2d") == ["east", "east", "north", "south", "south", "south", "up", "down", "down"]
    end

    test "handles bad input" do
      assert Command.Run.parse_run("2ef3s") == ["east", "east", "south", "south", "south"]
      assert Command.Run.parse_run("2en3s") == ["south", "south", "south"]
    end

    test "handles no directions" do
      assert Command.Run.parse_run("") == []
    end

    test "handles weird directions" do
      # no, rth
      assert Command.Run.parse_run("north") == []

      # e, a, s, t
      assert Command.Run.parse_run("east") == ["east", "south"]
    end
  end
end
