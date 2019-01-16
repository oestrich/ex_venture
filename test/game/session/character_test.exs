defmodule Game.Session.CharacterTest do
  use ExVenture.SessionCase

  alias Game.Session.Character
  alias Game.Session.State

  doctest Character

  setup do
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

      assert_socket_echo "player"
    end

    test "player going offline echos", %{state: state} do
      _state = Character.notify(state, {"player/offline", %{name: "Player"}})

      assert_socket_echo "player"
    end
  end
end
