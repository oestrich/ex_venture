defmodule Game.Command.SayTest do
  use Data.ModelCase
  doctest Game.Command.Say

  alias Game.Command.Say
  alias Game.Command.Say.ParsedMessage

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    @socket.clear_messages()
    user = create_user(%{name: "user", password: "password"})
    %{state: %{socket: :socket, user: user, save: user.save}}
  end

  describe "say to someone" do
    test "to a player", %{state: state} do
      player = %{id: 1, name: "Player"}
      @room.set_room(Map.merge(@room._room(), %{players: [player]}))

      :ok = Say.run({">player hi"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/"hi"/, echo)
    end

    test "to an npc", %{state: state} do
      guard = create_npc(%{name: "Guard"})
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))

      :ok = Say.run({">guard hi"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/"hi"/, echo)
    end

    test "target not found", %{state: state} do
      @room.set_room(@room._room())

      :ok = Say.run({">guard hi"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/no .+ could be found/i, echo)
    end
  end

  describe "parsing a say message" do
    test "simple" do
      assert %ParsedMessage{message: "hello"} = Say.parse_message("hello")
    end

    test "strips surrounding quotes" do
      assert %ParsedMessage{message: "hello"} = Say.parse_message("\"hello\"")
    end

    test "directed at someone" do
      assert %ParsedMessage{message: "guard hello", is_directed: true} = Say.parse_message(">guard hello")
    end
  end
end
