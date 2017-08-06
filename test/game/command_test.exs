defmodule CommandTest do
  use Data.ModelCase
  doctest Game.Command

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
      assert Command.parse("say hello") == {Command.Say, {"hello"}}
    end

    test "parsing global" do
      assert Command.parse("global hello") == {Command.Global, {"hello"}}
    end

    test "parsing who is online" do
      assert Command.parse("who") == {Command.Who, {}}
    end

    test "quitting" do
      assert Command.parse("quit") == {Command.Quit, {}}
    end

    test "getting help" do
      assert Command.parse("help") == {Command.Help, {}}
      assert Command.parse("help topic") == {Command.Help, {"topic"}}
    end

    test "looking" do
      assert Command.parse("look") == {Command.Look, {}}
      assert Command.parse("look at item") == {Command.Look, {"item"}}
      assert Command.parse("look item") == {Command.Look, {"item"}}
    end

    test "north" do
      assert Command.parse("north") == {Command.Move, {:north}}
      assert Command.parse("n") == {Command.Move, {:north}}
    end

    test "east" do
      assert Command.parse("east") == {Command.Move, {:east}}
      assert Command.parse("e") == {Command.Move, {:east}}
    end

    test "south" do
      assert Command.parse("south") == {Command.Move, {:south}}
      assert Command.parse("s") == {Command.Move, {:south}}
    end

    test "west" do
      assert Command.parse("west") == {Command.Move, {:west}}
      assert Command.parse("w") == {Command.Move, {:west}}
    end

    test "inventory" do
      assert Command.parse("inventory") == {Command.Inventory, {}}
      assert Command.parse("inv") == {Command.Inventory, {}}
    end

    test "pick up something" do
      assert Command.parse("pick up sword") == {Command.PickUp, {"sword"}}
    end

    test "info sheet" do
      assert Command.parse("info") == {Command.Info, {}}
    end

    test "wield" do
      assert Command.parse("wield sword") == {Command.Wield, {:wield, "sword"}}
    end

    test "unwield" do
      assert Command.parse("unwield sword") == {Command.Wield, {:unwield, "sword"}}
    end

    test "wear" do
      assert Command.parse("wear chest") == {Command.Wear, {:wear, "chest"}}
    end

    test "remove" do
      assert Command.parse("remove chest") == {Command.Wear, {:remove, "chest"}}
    end
  end

  describe "quitting" do
    test "quit command", %{session: session, socket: socket} do
      user = create_user(%{name: "user", password: "password", class_id: create_class().id})
      save = %{user.save | room_id: 5}

      :ok = Command.run({Command.Quit, {}}, session, %{socket: socket, user: user, save: save})

      assert @socket.get_echos() == [{socket, "Good bye."}]
      assert @socket.get_disconnects() == [socket]
    end
  end

  describe "getting help" do
    test "base help command", %{session: session, socket: socket} do
      Command.run({Command.Help, {}}, session, %{socket: socket})

      [{^socket, help}] = @socket.get_echos()
      assert Regex.match?(~r(The commands you can), help)
    end

    test "loading command help", %{session: session, socket: socket} do
      Command.run({Command.Help, {"say"}}, session, %{socket: socket})

      [{^socket, help}] = @socket.get_echos()
      assert Regex.match?(~r(say), help)
    end
  end

  describe "say" do
    test "says to the room", %{session: session, socket: socket} do
      Command.run({Command.Say, {"hi"}}, session, %{socket: socket, user: %{name: "user"}, save: %{room_id: 1}})

      assert @room.get_says() == [{1, Message.new(%{name: "user"}, "hi")}]
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
      Command.run({Command.Global, {"hi"}}, session, %{socket: socket, user: %{name: "user"}})
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
      {:update, state} = Command.run({Command.Move, {:north}}, session, Map.merge(state, %{save: %{room_id: 1}}))
      assert state.save.room_id == 2
    end

    test "cannot move north faster than the tick", %{session: session, socket: socket, state: state} do
      :ok = Command.run({Command.Move, {:north}}, session, Map.merge(state, %{save: %{room_id: 1}, last_tick: Timex.now() |> Timex.shift(minutes: -2)}))
      assert @socket.get_echos() == [{socket, "Slow down."}]
    end

    test "north - not found", %{session: session, state: state} do
      @room.set_room(%Data.Room{north_id: nil})
      :ok = Command.run({Command.Move, {:north}}, session, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "east", %{session: session, state: state} do
      @room.set_room(%Data.Room{name: "", description: "", east_id: 2, players: []})
      {:update, state} = Command.run({Command.Move, {:east}}, session, Map.merge(state, %{save: %{room_id: 1}}))
      assert state.save.room_id == 2
    end

    test "cannot move east faster than the tick", %{session: session, socket: socket, state: state} do
      :ok = Command.run({Command.Move, {:east}}, session, Map.merge(state, %{save: %{room_id: 1}, last_tick: Timex.now() |> Timex.shift(minutes: -2)}))
      assert @socket.get_echos() == [{socket, "Slow down."}]
    end

    test "east - not found", %{session: session, state: state} do
      @room.set_room(%Data.Room{east_id: nil})
      :ok = Command.run({Command.Move, {:east}}, session, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "south", %{session: session, state: state} do
      @room.set_room(%Data.Room{name: "", description: "", south_id: 2, players: []})
      {:update, state} = Command.run({Command.Move, {:south}}, session, Map.merge(state, %{save: %{room_id: 1}}))
      assert state.save.room_id == 2
    end

    test "cannot move south faster than the tick", %{session: session, socket: socket, state: state} do
      :ok = Command.run({Command.Move, {:south}}, session, Map.merge(state, %{save: %{room_id: 1}, last_tick: Timex.now() |> Timex.shift(minutes: -2)}))
      assert @socket.get_echos() == [{socket, "Slow down."}]
    end

    test "south - not found", %{session: session, state: state} do
      @room.set_room(%Data.Room{south_id: nil})
      :ok = Command.run({Command.Move, {:south}}, session, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "west", %{session: session, state: state} do
      @room.set_room(%Data.Room{name: "", description: "", west_id: 2, players: []})
      {:update, state} = Command.run({Command.Move, {:west}}, session, Map.merge(state, %{save: %{room_id: 1}}))
      assert state.save.room_id == 2
    end

    test "cannot move west faster than the tick", %{session: session, socket: socket, state: state} do
      :ok = Command.run({Command.Move, {:west}}, session, Map.merge(state, %{save: %{room_id: 1}, last_tick: Timex.now() |> Timex.shift(minutes: -2)}))
      assert @socket.get_echos() == [{socket, "Slow down."}]
    end

    test "west - not found", %{session: session, state: state} do
      @room.set_room(%Data.Room{west_id: nil})
      :ok = Command.run({Command.Move, {:west}}, session, Map.merge(state, %{save: %{room_id: 1}}))
    end
  end
end
