defmodule Game.Command.WhisperTest do
  use Data.ModelCase
  doctest Game.Command.Whisper

  alias Game.Command.Whisper

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    @socket.clear_messages()
    user = create_user(%{name: "user", password: "password"})
    %{state: session_state(%{user: user})}
  end

  describe "whisper to someone" do
    test "to a player", %{state: state} do
      player = %{id: 1, name: "Player"}
      @room.set_room(Map.merge(@room._room(), %{players: [player]}))

      :ok = Whisper.run({:whisper, "player hi"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/hi/, echo)
    end

    test "to an npc", %{state: state} do
      guard = create_npc(%{name: "Guard"})
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))

      :ok = Whisper.run({:whisper, "guard hi"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/hi/, echo)
    end

    test "target not found", %{state: state} do
      @room.set_room(@room._room())

      :ok = Whisper.run({:whisper, "guard hi"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/no .+ could be found/i, echo)
    end
  end
end
