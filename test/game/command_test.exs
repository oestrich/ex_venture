defmodule CommandTest do
  use Data.ModelCase
  doctest Game.Command

  alias Game.Command
  alias Game.Insight
  alias Game.Message
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
      assert Command.parse("does not exist", user) == {:error, :bad_parse, "does not exist"}
    end

    test "empty command", %{user: user} do
      assert Command.parse("", user) == {:skip, {}}
    end

    test "parsing say", %{user: user} do
      assert Command.parse("say hello", user) == {Command.Say, {"hello"}}
    end

    test "parsing global", %{user: user} do
      assert Command.parse("global hello", user) == {Command.Channels, {"global", "hello"}}
    end

    test "parsing tell", %{user: user} do
      assert Command.parse("tell player hello", user) == {Command.Tell, {"tell", "player hello"}}
    end

    test "parsing reply", %{user: user} do
      assert Command.parse("reply hello", user) == {Command.Tell, {"reply", "hello"}}
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

    test "equipment", %{user: user} do
      assert Command.parse("equipment", user) == {Command.Equipment, {}}
      assert Command.parse("eq", user) == {Command.Equipment, {}}
    end

    test "pick up something", %{user: user} do
      assert Command.parse("pick up sword", user) == {Command.PickUp, {"sword"}}
    end

    test "drop something", %{user: user} do
      assert Command.parse("drop sword", user) == {Command.Drop, {"sword"}}
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

    test "map", %{user: user} do
      assert Command.parse("map", user) == {Command.Map, {}}
    end

    test "examine", %{user: user} do
      assert Command.parse("examine", user) == {Command.Examine, {}}
    end

    test "shops", %{user: user} do
      assert Command.parse("shops", user) == {Command.Shops, {}}
      assert Command.parse("shops list tree top", user) == {Command.Shops, {:list, "tree top"}}
      assert Command.parse("shops buy item from tree top", user) == {Command.Shops, {:buy, "item", :from, "tree top"}}
    end
  end

  test "limit commands to be above 0 hp to perform", %{session: session, socket: socket} do
    save = %{stats: %{health: 0}}
    :ok = Command.run({Command.Move, {:north}}, session, %{socket: socket, save: save})
    assert @socket.get_echos() == [{socket, "You are passed out and cannot perform this action."}]
  end

  describe "bad parse" do
    setup do
      %{user: %{class: %{skills: []}}, state: %{socket: :socket}}
    end

    test "an unknown command is run", %{user: user, state: state} do
      "bad command" |> Command.parse(user) |> Command.run(self(), state)
      assert Insight.bad_commands |> length() > 0
    end
  end

  describe "empty command" do
    setup do
      %{user: %{class: %{skills: []}}, state: %{socket: :socket}}
    end

    test "an empty command is run", %{user: user, state: state} do
      assert :ok = "" |> Command.parse(user) |> Command.run(self(), state)
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
      assert Regex.match?(~r(The topics you can), help)
    end

    test "loading command help", %{session: session, socket: socket} do
      Command.run({Command.Help, {"say"}}, session, %{socket: socket})

      [{^socket, help}] = @socket.get_echos()
      assert Regex.match?(~r(say), help)
    end
  end

  describe "say" do
    setup do
      @room.clear_says()
    end

    test "says to the room", %{session: session, socket: socket} do
      Command.run({Command.Say, {"hi"}}, session, %{socket: socket, user: %{name: "user"}, save: %{room_id: 1}})

      assert @room.get_says() == [{1, Message.new(%{name: "user"}, "hi")}]
    end
  end

  describe "moving" do
    setup %{socket: socket} do
      user = %{id: 10}
      state = %{
        socket: socket,
        user: user,
      }
      %{user: user, state: state}
    end

    test "north", %{session: session, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 2, south_id: 1}], players: [], shops: []})
      {:update, state} = Command.run({Command.Move, {:north}}, session, Map.merge(state, %{save: %{room_id: 1}}))
      assert state.save.room_id == 2
    end

    test "north - not found", %{session: session, state: state} do
      @room.set_room(%Data.Room{exits: []})
      :ok = Command.run({Command.Move, {:north}}, session, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "east", %{session: session, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{west_id: 1, east_id: 2}], players: [], shops: []})
      {:update, state} = Command.run({Command.Move, {:east}}, session, Map.merge(state, %{save: %{room_id: 1}}))
      assert state.save.room_id == 2
    end

    test "east - not found", %{session: session, state: state} do
      @room.set_room(%Data.Room{exits: []})
      :ok = Command.run({Command.Move, {:east}}, session, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "south", %{session: session, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 1, south_id: 2}], players: [], shops: []})
      {:update, state} = Command.run({Command.Move, {:south}}, session, Map.merge(state, %{save: %{room_id: 1}}))
      assert state.save.room_id == 2
    end

    test "south - not found", %{session: session, state: state} do
      @room.set_room(%Data.Room{exits: []})
      :ok = Command.run({Command.Move, {:south}}, session, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "west", %{session: session, state: state} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{west_id: 2, east_id: 1}], players: [], shops: []})
      {:update, state} = Command.run({Command.Move, {:west}}, session, Map.merge(state, %{save: %{room_id: 1}}))
      assert state.save.room_id == 2
    end

    test "west - not found", %{session: session, state: state} do
      @room.set_room(%Data.Room{exits: []})
      :ok = Command.run({Command.Move, {:west}}, session, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "clears the target after moving", %{session: session, state: state, user: user} do
      @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 2, south_id: 1}], players: [], shops: []})
      Registry.register(user)

      state = Map.merge(state, %{user: user, save: %{room_id: 1}, target: {:user, 10}})
      {:update, state} = Command.run({Command.Move, {:north}}, session, state)

      assert state.target == nil
      assert_received {:"$gen_cast", {:remove_target, {:user, ^user}}}

      Registry.unregister()
    end
  end
end
