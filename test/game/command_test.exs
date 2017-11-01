defmodule CommandTest do
  use Data.ModelCase
  doctest Game.Command

  alias Game.Command
  alias Game.Insight
  alias Game.Message

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

    test "records how long it takes to parse a command", %{user: user} do
      command = Command.parse("say hello", user)
      assert is_integer(command.parsed_in)
    end

    test "allows capitalization of the command", %{user: user} do
      assert %Command{module: Command.Say, args: {"hello"}} = Command.parse("Say hello", user)
    end

    test "removes extra spaces", %{user: user} do
      assert %Command{module: Command.Say, args: {"hello how are you"}} = Command.parse("say  hello  how are you", user)
    end

    test "parsing say", %{user: user} do
      assert %Command{module: Command.Say, args: {"hello"}} = Command.parse("say hello", user)
    end

    test "parsing global", %{user: user} do
      assert %Command{module: Command.Channels, args: {"global", "hello"}} = Command.parse("global hello", user)
    end

    test "parsing tell", %{user: user} do
      assert %Command{module: Command.Tell, args: {"tell", "player hello"}} = Command.parse("tell player hello", user)
    end

    test "parsing reply", %{user: user} do
      assert %Command{module: Command.Tell, args: {"reply", "hello"}} = Command.parse("reply hello", user)
    end

    test "parsing who is online", %{user: user} do
      assert %Command{module: Command.Who, args: {}} = Command.parse("who", user)
    end

    test "quitting", %{user: user} do
      assert %Command{module: Command.Quit, args: {}} = Command.parse("quit", user)
    end

    test "getting help", %{user: user} do
      assert %Command{module: Command.Help, args: {}} = Command.parse("help", user)
      assert %Command{module: Command.Help, args: {"topic"}} = Command.parse("help topic", user)
    end

    test "looking", %{user: user} do
      assert %Command{module: Command.Look, args: {}} = Command.parse("look", user)
      assert %Command{module: Command.Look, args: {"item"}} = Command.parse("look at item", user)
      assert %Command{module: Command.Look, args: {"item"}} = Command.parse("look item", user)
    end

    test "open", %{user: user} do
      assert %Command{module: Command.Move, args: {:open, :north}} = Command.parse("open north", user)
      assert %Command{module: Command.Move, args: {:open, :north}} = Command.parse("open n", user)
      assert {:error, :bad_parse, "open unknown"} = Command.parse("open unknown", user).args
    end

    test "close", %{user: user} do
      assert %Command{module: Command.Move, args: {:close, :north}} = Command.parse("close north", user)
      assert %Command{module: Command.Move, args: {:close, :north}} = Command.parse("close n", user)
      assert {:error, :bad_parse, "close unknown"} = Command.parse("close unknown", user).args
    end

    test "north", %{user: user} do
      assert %Command{module: Command.Move, args: {:north}} = Command.parse("move north", user)
      assert %Command{module: Command.Move, args: {:north}} = Command.parse("north", user)
      assert %Command{module: Command.Move, args: {:north}} = Command.parse("n", user)
    end

    test "east", %{user: user} do
      assert %Command{module: Command.Move, args: {:east}} = Command.parse("move east", user)
      assert %Command{module: Command.Move, args: {:east}} = Command.parse("east", user)
      assert %Command{module: Command.Move, args: {:east}} = Command.parse("e", user)
    end

    test "south", %{user: user} do
      assert %Command{module: Command.Move, args: {:south}} = Command.parse("move south", user)
      assert %Command{module: Command.Move, args: {:south}} = Command.parse("south", user)
      assert %Command{module: Command.Move, args: {:south}} = Command.parse("s", user)
    end

    test "west", %{user: user} do
      assert %Command{module: Command.Move, args: {:west}} = Command.parse("move west", user)
      assert %Command{module: Command.Move, args: {:west}} = Command.parse("west", user)
      assert %Command{module: Command.Move, args: {:west}} = Command.parse("w", user)
    end

    test "up", %{user: user} do
      assert %Command{module: Command.Move, args: {:up}} = Command.parse("move up", user)
      assert %Command{module: Command.Move, args: {:up}} = Command.parse("up", user)
      assert %Command{module: Command.Move, args: {:up}} = Command.parse("u", user)
    end

    test "down", %{user: user} do
      assert %Command{module: Command.Move, args: {:down}} = Command.parse("move down", user)
      assert %Command{module: Command.Move, args: {:down}} = Command.parse("down", user)
      assert %Command{module: Command.Move, args: {:down}} = Command.parse("d", user)
    end

    test "inventory", %{user: user} do
      assert %Command{module: Command.Inventory, args: {}} = Command.parse("inventory", user)
      assert %Command{module: Command.Inventory, args: {}} = Command.parse("inv", user)
    end

    test "equipment", %{user: user} do
      assert %Command{module: Command.Equipment, args: {}} = Command.parse("equipment", user)
      assert %Command{module: Command.Equipment, args: {}} = Command.parse("eq", user)
    end

    test "pick up something", %{user: user} do
      assert %Command{module: Command.PickUp, args: {"sword"}} = Command.parse("pick up sword", user)
    end

    test "drop something", %{user: user} do
      assert %Command{module: Command.Drop, args: {"sword"}} = Command.parse("drop sword", user)
    end

    test "info sheet", %{user: user} do
      assert %Command{module: Command.Info, args: {}} = Command.parse("info", user)
    end

    test "wield", %{user: user} do
      assert %Command{module: Command.Wield, args: {:wield, "sword"}} = Command.parse("wield sword", user)
    end

    test "unwield", %{user: user} do
      assert %Command{module: Command.Wield, args: {:unwield, "sword"}} = Command.parse("unwield sword", user)
    end

    test "wear", %{user: user} do
      assert %Command{module: Command.Wear, args: {:wear, "chest"}} = Command.parse("wear chest", user)
    end

    test "remove", %{user: user} do
      assert %Command{module: Command.Wear, args: {:remove, "chest"}} = Command.parse("remove chest", user)
    end

    test "target", %{user: user} do
      assert %Command{module: Command.Target, args: {"mob"}} = Command.parse("target mob", user)
      assert %Command{module: Command.Target, args: {"mob"}} = Command.parse("t mob", user)
      assert %Command{module: Command.Target, args: {}} = Command.parse("target", user)
    end

    test "parsing class skills", %{user: user} do
      slash = %{command: "slash"}
      user = %{user | class: %{skills: [slash]}}

      assert %Command{module: Command.Skills, args: {^slash, "slash"}} = Command.parse("slash", user)
    end

    test "emoting", %{user: user} do
      assert %Command{module: Command.Emote, args: {"does something"}} = Command.parse("emote does something", user)
    end

    test "map", %{user: user} do
      assert %Command{module: Command.Map, args: {}} = Command.parse("map", user)
    end

    test "examine", %{user: user} do
      assert %Command{module: Command.Examine, args: {}} = Command.parse("examine", user)
    end

    test "shops", %{user: user} do
      assert %Command{module: Command.Shops, args: {}} = Command.parse("shops", user)
      assert %Command{module: Command.Shops, args: {:list, "tree top"}} = Command.parse("shops list tree top", user)
      assert %Command{module: Command.Shops, args: {:buy, "item", :from, "tree top"}} = Command.parse("shops buy item from tree top", user)
    end

    test "run", %{user: user} do
      assert %Command{module: Command.Run, args: {"3en4s"}} = Command.parse("run 3en4s", user)
    end

    test "bug", %{user: user} do
      assert %Command{module: Command.Bug, args: {"a bug title"}} = Command.parse("bug a bug title", user)
    end
  end

  test "limit commands to be above 0 hp to perform", %{session: session, socket: socket} do
    save = %{stats: %{health: 0}}
    command = %Command{module: Command.Move, args: {:north}}
    :ok = Command.run(command, session, %{socket: socket, save: save})
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

      command = %Command{module: Command.Quit}
      :ok = Command.run(command, session, %{socket: socket, user: user, save: save})

      assert @socket.get_echos() == [{socket, "Good bye."}]
      assert @socket.get_disconnects() == [socket]
    end
  end

  describe "getting help" do
    test "base help command", %{session: session, socket: socket} do
      command = %Command{module: Command.Help}
      {:paginate, text, _state} = Command.run(command, session, %{socket: socket})

      assert Regex.match?(~r(The topics you can), text)
    end

    test "loading command help", %{session: session, socket: socket} do
      command = %Command{module: Command.Help, args: {"say"}}
      {:paginate, text, _state} = Command.run(command, session, %{socket: socket})

      assert Regex.match?(~r(say), text)
    end
  end

  describe "say" do
    setup do
      @room.clear_says()
    end

    test "says to the room", %{session: session, socket: socket} do
      command = %Command{module: Command.Say, args: {"hi"}}
      Command.run(command, session, %{socket: socket, user: %{name: "user"}, save: %{room_id: 1}})

      assert @room.get_says() == [{1, Message.new(%{name: "user"}, "hi")}]
    end
  end
end
