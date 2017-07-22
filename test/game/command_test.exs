defmodule Game.CommandTest do
  use Data.ModelCase

  alias Game.Command
  alias Game.Message
  alias Game.Session

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket}}
  end

  describe "parsing commands" do
    test "command not found" do
      assert Command.parse("does not exist") == {:error, :bad_parse}
    end

    test "parsing say" do
      assert Command.parse("say hello") == {Game.Command.Say, ["hello"]}
    end

    test "parsing global" do
      assert Command.parse("global hello") == {Game.Command.Global, ["hello"]}
    end

    test "parsing who is online" do
      assert Command.parse("who is online") == {Game.Command.Who, []}
      assert Command.parse("who") == {Game.Command.Who, []}
    end

    test "quitting" do
      assert Command.parse("quit") == {Game.Command.Quit, []}
    end

    test "getting help" do
      assert Command.parse("help") == {Game.Command.Help, []}
      assert Command.parse("help topic") == {Game.Command.Help, ["topic"]}
    end

    test "looking" do
      assert Command.parse("look") == {Game.Command.Look, []}
      assert Command.parse("look item") == {Game.Command.Look, ["item"]}
    end

    test "north" do
      assert Command.parse("north") == {Game.Command.Move, [:north]}
      assert Command.parse("n") == {Game.Command.Move, [:north]}
    end

    test "east" do
      assert Command.parse("east") == {Game.Command.Move, [:east]}
      assert Command.parse("e") == {Game.Command.Move, [:east]}
    end

    test "south" do
      assert Command.parse("south") == {Game.Command.Move, [:south]}
      assert Command.parse("s") == {Game.Command.Move, [:south]}
    end

    test "west" do
      assert Command.parse("west") == {Game.Command.Move, [:west]}
      assert Command.parse("w") == {Game.Command.Move, [:west]}
    end
  end

  describe "quitting" do
    test "quit command", %{session: session, socket: socket} do
      user = create_user(%{username: "user", password: "password"})

      :ok = Command.run({Game.Command.Quit, []}, session, %{socket: socket, user: user, save: %{room_id: 5}})

      assert @socket.get_echos() == [{socket, "Good bye."}]
      assert @socket.get_disconnects() == [socket]

      user = Data.User |> Repo.get(user.id)
      assert user.save.room_id == 5
    end
  end

  describe "getting help" do
    test "base help command", %{session: session, socket: socket} do
      Command.run({Game.Command.Help, []}, session, %{socket: socket})

      [{^socket, help}] = @socket.get_echos()
      assert Regex.match?(~r(The commands you can), help)
    end

    test "loading command help", %{session: session, socket: socket} do
      Command.run({Game.Command.Help, ["say"]}, session, %{socket: socket})

      [{^socket, help}] = @socket.get_echos()
      assert Regex.match?(~r(say), help)
    end
  end

  describe "say" do
    test "says to the room", %{session: session, socket: socket} do
      Command.run({Game.Command.Say, ["hi"]}, session, %{socket: socket, user: %{username: "user"}, save: %{room_id: 1}})

      assert @room.get_says() == [{1, Message.new(%{username: "user"}, "hi")}]
    end
  end

  describe "global" do
    setup do
      Session.Registry.register({self(), :user})
      on_exit fn() ->
        Session.Registry.unregister()
      end
    end

    test "talk on the global channel", %{session: session, socket: socket} do
      Command.run({Game.Command.Global, ["hi"]}, session, %{socket: socket, user: %{username: "user"}})
      assert_received {:"$gen_cast", {:echo, ~s({red}[global]{/red} {blue}user{/blue} says, {green}"hi"{/green})}}
    end
  end

  describe "moving" do
    setup %{socket: socket} do
      user = %{}
      state = %{
        socket: socket,
        user: user,
        last_move: Timex.now() |> Timex.shift(minutes: -1),
        last_tick: Timex.now(),
      }
      %{user: user, state: state}
    end

    test "north", %{session: session, state: state} do
      @room.set_room(%Data.Room{name: "", description: "", north_id: 2, players: []})
      {:update, state} = Command.run({Game.Command.Move, [:north]}, session, Map.merge(state, %{save: %{room_id: 1}}))
      assert state.save.room_id == 2
    end

    test "cannot move north faster than the tick", %{session: session, socket: socket, state: state} do
      :ok = Command.run({Game.Command.Move, [:north]}, session, Map.merge(state, %{save: %{room_id: 1}, last_tick: Timex.now() |> Timex.shift(minutes: -2)}))
      assert @socket.get_echos() == [{socket, "Slow down."}]
    end

    test "north - not found", %{session: session, state: state} do
      @room.set_room(%Data.Room{north_id: nil})
      :ok = Command.run({Game.Command.Move, [:north]}, session, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "east", %{session: session, state: state} do
      @room.set_room(%Data.Room{name: "", description: "", east_id: 2, players: []})
      {:update, state} = Command.run({Game.Command.Move, [:east]}, session, Map.merge(state, %{save: %{room_id: 1}}))
      assert state.save.room_id == 2
    end

    test "cannot move east faster than the tick", %{session: session, socket: socket, state: state} do
      :ok = Command.run({Game.Command.Move, [:east]}, session, Map.merge(state, %{save: %{room_id: 1}, last_tick: Timex.now() |> Timex.shift(minutes: -2)}))
      assert @socket.get_echos() == [{socket, "Slow down."}]
    end

    test "east - not found", %{session: session, state: state} do
      @room.set_room(%Data.Room{east_id: nil})
      :ok = Command.run({Game.Command.Move, [:east]}, session, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "south", %{session: session, state: state} do
      @room.set_room(%Data.Room{name: "", description: "", south_id: 2, players: []})
      {:update, state} = Command.run({Game.Command.Move, [:south]}, session, Map.merge(state, %{save: %{room_id: 1}}))
      assert state.save.room_id == 2
    end

    test "cannot move south faster than the tick", %{session: session, socket: socket, state: state} do
      :ok = Command.run({Game.Command.Move, [:south]}, session, Map.merge(state, %{save: %{room_id: 1}, last_tick: Timex.now() |> Timex.shift(minutes: -2)}))
      assert @socket.get_echos() == [{socket, "Slow down."}]
    end

    test "south - not found", %{session: session, state: state} do
      @room.set_room(%Data.Room{south_id: nil})
      :ok = Command.run({Game.Command.Move, [:south]}, session, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "west", %{session: session, state: state} do
      @room.set_room(%Data.Room{name: "", description: "", west_id: 2, players: []})
      {:update, state} = Command.run({Game.Command.Move, [:west]}, session, Map.merge(state, %{save: %{room_id: 1}}))
      assert state.save.room_id == 2
    end

    test "cannot move west faster than the tick", %{session: session, socket: socket, state: state} do
      :ok = Command.run({Game.Command.Move, [:west]}, session, Map.merge(state, %{save: %{room_id: 1}, last_tick: Timex.now() |> Timex.shift(minutes: -2)}))
      assert @socket.get_echos() == [{socket, "Slow down."}]
    end

    test "west - not found", %{session: session, state: state} do
      @room.set_room(%Data.Room{west_id: nil})
      :ok = Command.run({Game.Command.Move, [:west]}, session, Map.merge(state, %{save: %{room_id: 1}}))
    end
  end
end
