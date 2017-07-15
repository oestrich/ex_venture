defmodule Game.CommandTest do
  use ExUnit.Case

  alias Game.Command

  @socket Test.Networking.Socket

  setup do
    socket = :socket
    @socket.clear_messages
    {:ok, %{socket: socket}}
  end

  describe "parsing commands" do
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

    test "command not found" do
      assert Command.parse("does not exist") == {:error, :bad_parse}
    end
  end

  describe "find out who is online" do
  end

  describe "quitting" do
    test "quit command", %{socket: socket} do
      Command.run({:quit}, %{socket: socket})

      assert @socket.get_echos() == [{socket, "Good bye."}]
      assert @socket.get_disconnects() == [socket]
    end
  end

  describe "getting help" do
    test "base help command", %{socket: socket} do
      Command.run({:help}, %{socket: socket})

      [{^socket, help}] = @socket.get_echos()
      assert Regex.match?(~r(The commands you can), help)
    end

    test "loading command help", %{socket: socket} do
      Command.run({:help, "say"}, %{socket: socket})

      [{^socket, help}] = @socket.get_echos()
      assert Regex.match?(~r(say), help)
    end
  end
end
