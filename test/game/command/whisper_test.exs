defmodule Game.Command.WhisperTest do
  use ExVenture.CommandCase

  alias Game.Character
  alias Game.Command.Whisper

  doctest Whisper

  setup do
    user = create_user(%{name: "user", password: "password"})
    character = create_character(user)
    %{state: session_state(%{user: user, character: character})}
  end

  describe "whisper to someone" do
    test "to a player", %{state: state} do
      player = %{base_character(base_user()) | id: 1, name: "Player"}
      start_room(%{players: [Character.to_simple(player)]})

      :ok = Whisper.run({:whisper, "player hi"}, state)

      assert_socket_echo "hi"
    end

    test "to an npc", %{state: state} do
      guard = create_npc(%{name: "Guard"})
      start_room(%{npcs: [Character.to_simple(guard)]})

      :ok = Whisper.run({:whisper, "guard hi"}, state)

      assert_socket_echo "hi"
    end

    test "target not found", %{state: state} do
      start_room(%{})

      :ok = Whisper.run({:whisper, "guard hi"}, state)

      assert_socket_echo "no .+ could be found"
    end
  end
end
