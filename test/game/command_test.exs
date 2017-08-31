defmodule CommandTest do
  use Data.ModelCase
  doctest Game.Command

  alias Game.Command
  alias Game.Message
  alias Game.Session
  alias Game.Session.Registry

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket}}
  end

  describe "parsing commands" do
    setup do
      %{user: %{class: %{skills: []}}}
    end

    test "command not found", %{user: user} do
      assert Command.parse("does not exist", user) == {:error, :bad_parse}
    end

    test "parsing say", %{user: user} do
      assert Command.parse("say hello", user) == {Command.Say, {"hello"}}
    end

    test "parsing global", %{user: user} do
      assert Command.parse("global hello", user) == {Command.Global, {"hello"}}
    end

    test "parsing who is online", %{user: user} do
      assert Command.parse("who", user) == {Command.Who, {}}
    end

    test "quitting", %{user: user} do
      assert Command.parse("quit", user) == {Command.Quit, {}}
    end

    test "getting help", %{user: user} do
      assert Command.parse("help", user) == {Command.Help, {}}
      assert Command.parse("help topic", user) == {Command.Help, {"topic"}}
    end

    test "looking", %{user: user} do
      assert Command.parse("look", user) == {Command.Look, {}}
      assert Command.parse("look at item", user) == {Command.Look, {"item"}}
      assert Command.parse("look item", user) == {Command.Look, {"item"}}
    end

    test "north", %{user: user} do
      assert Command.parse("north", user) == {Command.Move, {:north}}
      assert Command.parse("n", user) == {Command.Move, {:north}}
    end

    test "east", %{user: user} do
      assert Command.parse("east", user) == {Command.Move, {:east}}
      assert Command.parse("e", user) == {Command.Move, {:east}}
    end

    test "south", %{user: user} do
      assert Command.parse("south", user) == {Command.Move, {:south}}
      assert Command.parse("s", user) == {Command.Move, {:south}}
    end

    test "west", %{user: user} do
      assert Command.parse("west", user) == {Command.Move, {:west}}
      assert Command.parse("w", user) == {Command.Move, {:west}}
    end

    test "inventory", %{user: user} do
      assert Command.parse("inventory", user) == {Command.Inventory, {}}
      assert Command.parse("inv", user) == {Command.Inventory, {}}
    end

    test "pick up something", %{user: user} do
      assert Command.parse("pick up sword", user) == {Command.PickUp, {"sword"}}
    end

    test "info sheet", %{user: user} do
      assert Command.parse("info", user) == {Command.Info, {}}
    end

    test "wield", %{user: user} do
      assert Command.parse("wield sword", user) == {Command.Wield, {:wield, "sword"}}
    end

    test "unwield", %{user: user} do
      assert Command.parse("unwield sword", user) == {Command.Wield, {:unwield, "sword"}}
    end

    test "wear", %{user: user} do
      assert Command.parse("wear chest", user) == {Command.Wear, {:wear, "chest"}}
    end

    test "remove", %{user: user} do
      assert Command.parse("remove chest", user) == {Command.Wear, {:remove, "chest"}}
    end

    test "target", %{user: user} do
      assert Command.parse("target mob", user) == {Command.Target, {"mob"}}
      assert Command.parse("target", user) == {Command.Target, {}}
    end

    test "parsing class skills", %{user: user} do
      slash = %{command: "slash"}
      user = %{user | class: %{skills: [slash]}}

      assert Command.parse("slash", user) == {Command.Skills, {slash, "slash"}}
    end

    test "emoting", %{user: user} do
      assert Command.parse("emote does something", user) == {Command.Emote, {"does something"}}
    end
  end

  test "limit commands to be above 0 hp to perform", %{session: session, socket: socket} do
    save = %{stats: %{health: 0}}
    :ok = Command.run({Command.Move, {:north}}, session, %{socket: socket, save: save})
    assert @socket.get_echos() == [{socket, "You are passed out and cannot perform this action."}]
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
      assert Regex.match?(~r(The topics you can), help)
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
      user = %{id: 10}
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

    test "clears the target after moving", %{session: session, state: state, user: user} do
      @room.set_room(%Data.Room{name: "", description: "", north_id: 2, players: []})
      Registry.register(user)

      state = Map.merge(state, %{user: user, save: %{room_id: 1}, target: {:user, 10}})
      {:update, state} = Command.run({Command.Move, {:north}}, session, state)

      assert state.target == nil
      assert_received {:"$gen_cast", {:remove_target, {:user, ^user}}}

      Registry.unregister()
    end
  end
end
