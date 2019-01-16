defmodule Game.Command.WhisperTest do
  use ExVenture.CommandCase

  alias Game.Command.Whisper

  doctest Whisper

  @room Test.Game.Room

  setup do
    user = create_user(%{name: "user", password: "password"})
    character = create_character(user)
    %{state: session_state(%{user: user, character: character})}
  end

  describe "whisper to someone" do
    test "to a player", %{state: state} do
      player = %{id: 1, name: "Player"}
      @room.set_room(Map.merge(@room._room(), %{players: [player]}))

      :ok = Whisper.run({:whisper, "player hi"}, state)

      assert_socket_echo "hi"
    end

    test "to an npc", %{state: state} do
      guard = create_npc(%{name: "Guard"})
      @room.set_room(Map.merge(@room._room(), %{npcs: [guard]}))

      :ok = Whisper.run({:whisper, "guard hi"}, state)

      assert_socket_echo "hi"
    end

    test "target not found", %{state: state} do
      @room.set_room(@room._room())

      :ok = Whisper.run({:whisper, "guard hi"}, state)

      assert_socket_echo "no .+ could be found"
    end
  end
end
