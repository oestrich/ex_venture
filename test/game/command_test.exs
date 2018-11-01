defmodule Game.CommandTest do
  use Data.ModelCase
  doctest Game.Command

  alias Game.Command
  alias Game.Command.ParseContext
  alias Game.Insight

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages
    {:ok, %{socket: :socket}}
  end

  describe "parsing commands" do
    setup do
      character = %{save: %{skill_ids: [], items: []}}

      context = %ParseContext{
        player: character
      }

      %{context: context}
    end

    test "command not found", %{context: context} do
      assert Command.parse("does not exist", context) == {:error, :bad_parse, "does not exist"}
    end

    test "empty command", %{context: context} do
      assert Command.parse("", context) == {:skip, {}}
    end

    test "records how long it takes to parse a command", %{context: context} do
      command = Command.parse("say hello", context)
      assert is_integer(command.parsed_in)
    end

    test "removes extra spaces", %{context: context} do
      assert %Command{module: Command.Say, args: {"hello how are you"}} = Command.parse("say  hello  how are you", context)
    end

    test "parsing say", %{context: context} do
      assert %Command{module: Command.Say, args: {"hello"}} = Command.parse("say hello", context)
    end

    test "parsing tell", %{context: context} do
      assert %Command{module: Command.Tell, args: {"tell", "player hello"}} = Command.parse("tell player hello", context)
    end

    test "parsing reply", %{context: context} do
      assert %Command{module: Command.Tell, args: {"reply", "hello"}} = Command.parse("reply hello", context)
    end

    test "parsing who is online", %{context: context} do
      assert %Command{module: Command.Who, args: {}} = Command.parse("who", context)
    end

    test "quitting", %{context: context} do
      assert %Command{module: Command.Quit, args: {}} = Command.parse("quit", context)
    end

    test "getting help", %{context: context} do
      assert %Command{module: Command.Help, args: {}} = Command.parse("help", context)
      assert %Command{module: Command.Help, args: {"topic"}} = Command.parse("help topic", context)
    end

    test "looking", %{context: context} do
      assert %Command{module: Command.Look, args: {}} = Command.parse("look", context)
      assert %Command{module: Command.Look, args: {:other, "item"}} = Command.parse("look at item", context)
      assert %Command{module: Command.Look, args: {:other, "item"}} = Command.parse("look item", context)
    end

    test "open", %{context: context} do
      assert %Command{module: Command.Move, args: {:open, "north"}} = Command.parse("open north", context)
      assert %Command{module: Command.Move, args: {:open, "north"}} = Command.parse("open n", context)
      assert {:error, :bad_parse, "open unknown"} = Command.parse("open unknown", context)
    end

    test "close", %{context: context} do
      assert %Command{module: Command.Move, args: {:close, "north"}} = Command.parse("close north", context)
      assert %Command{module: Command.Move, args: {:close, "north"}} = Command.parse("close n", context)
      assert {:error, :bad_parse, "close unknown"} = Command.parse("close unknown", context)
    end

    test "north", %{context: context} do
      assert %Command{module: Command.Move, args: {:move, "north"}} = Command.parse("move north", context)
      assert %Command{module: Command.Move, args: {:move, "north"}} = Command.parse("north", context)
      assert %Command{module: Command.Move, args: {:move, "north"}} = Command.parse("n", context)
    end

    test "east", %{context: context} do
      assert %Command{module: Command.Move, args: {:move, "east"}} = Command.parse("move east", context)
      assert %Command{module: Command.Move, args: {:move, "east"}} = Command.parse("east", context)
      assert %Command{module: Command.Move, args: {:move, "east"}} = Command.parse("e", context)
    end

    test "south", %{context: context} do
      assert %Command{module: Command.Move, args: {:move, "south"}} = Command.parse("move south", context)
      assert %Command{module: Command.Move, args: {:move, "south"}} = Command.parse("south", context)
      assert %Command{module: Command.Move, args: {:move, "south"}} = Command.parse("s", context)
    end

    test "west", %{context: context} do
      assert %Command{module: Command.Move, args: {:move, "west"}} = Command.parse("move west", context)
      assert %Command{module: Command.Move, args: {:move, "west"}} = Command.parse("west", context)
      assert %Command{module: Command.Move, args: {:move, "west"}} = Command.parse("w", context)
    end

    test "up", %{context: context} do
      assert %Command{module: Command.Move, args: {:move, "up"}} = Command.parse("move up", context)
      assert %Command{module: Command.Move, args: {:move, "up"}} = Command.parse("up", context)
      assert %Command{module: Command.Move, args: {:move, "up"}} = Command.parse("u", context)
    end

    test "down", %{context: context} do
      assert %Command{module: Command.Move, args: {:move, "down"}} = Command.parse("move down", context)
      assert %Command{module: Command.Move, args: {:move, "down"}} = Command.parse("down", context)
      assert %Command{module: Command.Move, args: {:move, "down"}} = Command.parse("d", context)
    end

    test "inventory", %{context: context} do
      assert %Command{module: Command.Inventory, args: {}} = Command.parse("inventory", context)
      assert %Command{module: Command.Inventory, args: {}} = Command.parse("inv", context)
    end

    test "equipment", %{context: context} do
      assert %Command{module: Command.Equipment, args: {}} = Command.parse("equipment", context)
      assert %Command{module: Command.Equipment, args: {}} = Command.parse("eq", context)
    end

    test "pick up something", %{context: context} do
      assert %Command{module: Command.PickUp, args: {"sword"}} = Command.parse("pick up sword", context)
      assert %Command{module: Command.PickUp, args: {"sword"}} = Command.parse("get sword", context)
      assert %Command{module: Command.PickUp, args: {"sword"}} = Command.parse("take sword", context)
    end

    test "drop something", %{context: context} do
      assert %Command{module: Command.Drop, args: {"sword"}} = Command.parse("drop sword", context)
    end

    test "info sheet", %{context: context} do
      assert %Command{module: Command.Info, args: {}} = Command.parse("info", context)
    end

    test "wield", %{context: context} do
      assert %Command{module: Command.Wield, args: {:wield, "sword"}} = Command.parse("wield sword", context)
    end

    test "unwield", %{context: context} do
      assert %Command{module: Command.Wield, args: {:unwield, "sword"}} = Command.parse("unwield sword", context)
    end

    test "wear", %{context: context} do
      assert %Command{module: Command.Wear, args: {:wear, "chest"}} = Command.parse("wear chest", context)
    end

    test "remove", %{context: context} do
      assert %Command{module: Command.Wear, args: {:remove, "chest"}} = Command.parse("remove chest", context)
    end

    test "target", %{context: context} do
      assert %Command{module: Command.Target, args: {:set, "mob"}} = Command.parse("target mob", context)
      assert %Command{module: Command.Target, args: {:set, "mob"}} = Command.parse("t mob", context)
      assert %Command{module: Command.Target, args: {}} = Command.parse("target", context)
    end

    test "parsing skills", %{context: context} do
      start_and_clear_skills()
      slash = %{id: 1, level: 1, is_enabled: true, command: "slash"}
      insert_skill(slash)

      player = %{context.player | save: %{level: 1, skill_ids: [slash.id]}}
      context = %{context | player: player}

      assert %Command{module: Command.Skills, args: {^slash, "slash"}} = Command.parse("slash", context)
    end

    test "emoting", %{context: context} do
      assert %Command{module: Command.Emote, args: {"does something"}} = Command.parse("emote does something", context)
    end

    test "map", %{context: context} do
      assert %Command{module: Command.Map, args: {}} = Command.parse("map", context)
    end

    test "examine", %{context: context} do
      assert %Command{module: Command.Examine, args: {}} = Command.parse("examine", context)
    end

    test "shops", %{context: context} do
      assert %Command{module: Command.Shops, args: {}} = Command.parse("shops", context)
      assert %Command{module: Command.Shops, args: {:list, "tree top"}} = Command.parse("shops list tree top", context)
      assert %Command{module: Command.Shops, args: {:buy, "item", :from, "tree top"}} = Command.parse("shops buy item from tree top", context)
    end

    test "run", %{context: context} do
      assert %Command{module: Command.Run, args: {"3en4s"}} = Command.parse("run 3en4s", context)
    end

    test "bug", %{context: context} do
      assert %Command{module: Command.Bug, args: {:new, "a bug title"}} = Command.parse("bug a bug title", context)
    end

    test "typo", %{context: context} do
      assert %Command{module: Command.Typo, args: {"a typo title"}} = Command.parse("typo a typo title", context)
    end

    test "version", %{context: context} do
      assert %Command{module: Command.Version, args: {}} = Command.parse("version", context)
    end

    test "mistakes", %{context: context} do
      assert %Command{module: Command.Mistake, args: {:auto_combat}} = Command.parse("kill npc", context)
    end

    test "using items", %{context: context} do
      assert %Command{module: Command.Use, args: {:use, "potion"}} = Command.parse("use potion", context)
    end

    test "mail", %{context: context} do
      assert %Command{module: Command.Mail, args: {:unread}} = Command.parse("mail", context)
    end

    test "greet", %{context: context} do
      assert %Command{module: Command.Greet, args: {:greet, "guard"}} = Command.parse("greet guard", context)
      assert %Command{module: Command.Greet, args: {:greet, "guard"}} = Command.parse("talk to guard", context)
    end

    test "quest", %{context: context} do
      assert %Command{module: Command.Quest, args: {:list, :active}} = Command.parse("quest", context)
    end

    test "crash", %{context: context} do
      assert %Command{module: Command.Crash, args: {:room}} = Command.parse("crash room", context)
    end

    test "train", %{context: context} do
      assert %Command{module: Command.Train, args: {:list}} = Command.parse("train list", context)
    end

    test "recall", %{context: context} do
      assert %Command{module: Command.Recall, args: {}} = Command.parse("recall", context)
    end

    test "giving", %{context: context} do
      assert %Command{module: Command.Give, args: {"item", :to, "player"}} = Command.parse("give item to player", context)
    end

    test "socials", %{context: context} do
      assert %Command{module: Command.Socials, args: {:list}} = Command.parse("socials", context)
    end

    test "config", %{context: context} do
      assert %Command{module: Command.Config, args: {:list}} = Command.parse("config", context)
    end

    test "afk", %{context: context} do
      assert %Command{module: Command.AFK, args: {:toggle}} = Command.parse("afk", context)
    end

    test "whisper", %{context: context} do
      assert %Command{module: Command.Whisper, args: {:whisper, "player hi"}} = Command.parse("whisper player hi", context)
    end

    test "hone", %{context: context} do
      assert %Command{module: Command.Hone, args: {:hone, "strength"}} = Command.parse("hone strength", context)
    end

    test "colors", %{context: context} do
      assert %Command{module: Command.Colors, args: {:list}} = Command.parse("colors", context)
    end

    test "listen", %{context: context} do
      assert %Command{module: Command.Listen, args: {}} = Command.parse("listen", context)
    end

    test "debug", %{context: context} do
      assert %Command{module: Command.Debug, args: {:squabble}} = Command.parse("debug info", context)
    end

    test "scan", %{context: context} do
      assert %Command{module: Command.Scan, args: {}} = Command.parse("scan", context)
    end
  end

  test "limit commands to be above 0 hp to perform", %{socket: socket} do
    save = %{stats: %{health_points: 0}}
    command = %Command{module: Command.Move, args: {"north"}}
    :ok = Command.run(command, %{socket: socket, save: save})
    assert @socket.get_echos() == [{socket, "You are passed out and cannot perform this action."}]
  end

  describe "bad parse" do
    setup do
      user = %{save: %{skill_ids: [], items: []}}

      context = %ParseContext{
        player: user
      }

      %{context: context, state: %{socket: :socket}}
    end

    test "an unknown command is run", %{context: context, state: state} do
      "bad command" |> Command.parse(context) |> Command.run(state)
      assert Insight.bad_commands |> length() > 0
    end
  end

  describe "empty command" do
    setup do
      user = %{save: %{skill_ids: []}}

      context = %ParseContext{
        player: user
      }

      %{context: context, state: %{socket: :socket}}
    end

    test "an empty command is run", %{context: context, state: state} do
      assert :ok = "" |> Command.parse(context) |> Command.run(state)
    end
  end

  describe "quitting" do
    test "quit command", %{socket: socket} do
      user = create_user(%{name: "user", password: "password", class_id: create_class().id})
      character = create_character(user)
      save = %{character.save | room_id: 5}

      command = %Command{module: Command.Quit}
      :ok = Command.run(command, %{socket: socket, character: character, save: save})

      assert @socket.get_echos() == [{socket, "Good bye."}]
      assert @socket.get_disconnects() == [socket]
    end
  end

  describe "getting help" do
    test "base help command", %{socket: socket} do
      command = %Command{module: Command.Help}
      {:paginate, text, _state} = Command.run(command, %{socket: socket, user: %{flags: []}})

      assert Regex.match?(~r(The topics you can), text)
    end

    test "loading command help", %{socket: socket} do
      command = %Command{module: Command.Help, args: {"say"}}
      {:paginate, text, _state} = Command.run(command, %{socket: socket, user: %{flags: []}})

      assert Regex.match?(~r(say), text)
    end
  end
end
