defmodule Game.Session.CharacterTest do
  use Data.ModelCase
  doctest Game.Session.Character

  alias Game.Session.Character
  alias Game.Session.State

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages()

    state = %State{
      socket: :socket,
      state: "active",
      mode: "commands",
    }

    %{state: state}
  end

  describe "player online/offline" do
    test "player going online echos", %{state: state} do
      _state = Character.notify(state, {"player/online", %{name: "Player"}})

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/Player/i, echo)
    end

    test "player going offline echos", %{state: state} do
      _state = Character.notify(state, {"player/offline", %{name: "Player"}})

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/Player/i, echo)
    end
  end
end
