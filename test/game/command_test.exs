defmodule Game.CommandTest do
  use Data.ModelCase

  alias Game.Command

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
      assert Command.parse("say hello") == {:say, "hello"}
    end

    test "parsing who is online" do
      assert Command.parse("who is online") == {:who}
      assert Command.parse("who") == {:who}
    end

    test "quitting" do
      assert Command.parse("quit") == {:quit}
    end

    test "getting help" do
      assert Command.parse("help") == {:help}
      assert Command.parse("help topic") == {:help, "topic"}
    end

    test "looking" do
      assert Command.parse("look") == {:look}
    end

    test "north" do
      assert Command.parse("north") == {:north}
      assert Command.parse("n") == {:north}
    end

    test "east" do
      assert Command.parse("east") == {:east}
      assert Command.parse("e") == {:east}
    end

    test "south" do
      assert Command.parse("south") == {:south}
      assert Command.parse("s") == {:south}
    end

    test "west" do
      assert Command.parse("west") == {:west}
      assert Command.parse("w") == {:west}
    end
  end

  describe "quitting" do
    test "quit command", %{session: session, socket: socket} do
      user = create_user(%{username: "user", password: "password"})

      :ok = Command.run({:quit}, session, %{socket: socket, user: user, save: %{room_id: 5}})

      assert @socket.get_echos() == [{socket, "Good bye."}]
      assert @socket.get_disconnects() == [socket]

      user = Data.User |> Repo.get(user.id)
      assert user.save.room_id == 5
    end
  end

  describe "getting help" do
    test "base help command", %{session: session, socket: socket} do
      Command.run({:help}, session, %{socket: socket})

      [{^socket, help}] = @socket.get_echos()
      assert Regex.match?(~r(The commands you can), help)
    end

    test "loading command help", %{session: session, socket: socket} do
      Command.run({:help, "say"}, session, %{socket: socket})

      [{^socket, help}] = @socket.get_echos()
      assert Regex.match?(~r(say), help)
    end
  end

  describe "looking" do
    setup do
      @room.set_room(@room._room())
      :ok
    end

    test "view room information", %{session: session, socket: socket} do
      Command.run({:look}, session, %{socket: socket, save: %{room_id: 1}})

      [{^socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Hallway), look)
      assert Regex.match?(~r(Exits), look)
    end
  end

  describe "moving" do
    setup do
      %{user: %{}}
    end

    test "north", %{session: session, socket: socket, user: user} do
      @room.set_room(%Data.Room{north_id: 2, players: []})
      {:update, state} = Command.run({:north}, session, %{socket: socket, user: user, save: %{room_id: 1}})
      assert state.save.room_id == 2
    end

    test "north - not found", %{session: session, socket: socket} do
      @room.set_room(%Data.Room{north_id: nil})
      :ok = Command.run({:north}, session, %{socket: socket, save: %{room_id: 1}})
    end

    test "east", %{session: session, socket: socket, user: user} do
      @room.set_room(%Data.Room{east_id: 2, players: []})
      {:update, state} = Command.run({:east}, session, %{socket: socket, user: user, save: %{room_id: 1}})
      assert state.save.room_id == 2
    end

    test "east - not found", %{session: session, socket: socket} do
      @room.set_room(%Data.Room{east_id: nil})
      :ok = Command.run({:east}, session, %{socket: socket, save: %{room_id: 1}})
    end

    test "south", %{session: session, socket: socket, user: user} do
      @room.set_room(%Data.Room{south_id: 2, players: []})
      {:update, state} = Command.run({:south}, session, %{socket: socket, user: user, save: %{room_id: 1}})
      assert state.save.room_id == 2
    end

    test "south - not found", %{session: session, socket: socket} do
      @room.set_room(%Data.Room{south_id: nil})
      :ok = Command.run({:south}, session, %{socket: socket, save: %{room_id: 1}})
    end

    test "west", %{session: session, socket: socket, user: user} do
      @room.set_room(%Data.Room{west_id: 2, players: []})
      {:update, state} = Command.run({:west}, session, %{socket: socket, user: user, save: %{room_id: 1}})
      assert state.save.room_id == 2
    end

    test "west - not found", %{session: session, socket: socket} do
      @room.set_room(%Data.Room{west_id: nil})
      :ok = Command.run({:west}, session, %{socket: socket, save: %{room_id: 1}})
    end
  end
end
