defmodule Game.Session.GMCPTest do
  use ExVenture.SessionCase

  alias Game.Session.GMCP
  alias Game.Session.State

  setup do
    state = %State{
      socket: :socket,
      state: "active",
      mode: "commands",
    }

    %{state: state}
  end

  test "character enters - player", %{state: state} do
    GMCP.character_enter(state, %{type: "player", id: 10, name: "user"})

    assert_socket_gmcp {"Room.Character.Enter", json}
    assert Poison.decode!(json) == %{"type" => "player", "id" => 10, "name" => "user"}
  end

  test "character enters - npc", %{state: state} do
    GMCP.character_enter(state, %{type: "npc", id: 10, name: "Bandit"})

    assert_socket_gmcp {"Room.Character.Enter", json}
    assert Poison.decode!(json) == %{"type" => "npc", "id" => 10, "name" => "Bandit"}
  end

  test "character leaves - player", %{state: state} do
    GMCP.character_leave(state, %{type: "player", id: 10, name: "user"})

    assert_socket_gmcp {"Room.Character.Leave", json}
    assert Poison.decode!(json) == %{"type" => "player", "id" => 10, "name" => "user"}
  end

  test "character leaves - npc", %{state: state} do
    GMCP.character_leave(state, %{type: "npc", id: 10, name: "user"})

    assert_socket_gmcp {"Room.Character.Leave", json}
    assert Poison.decode!(json) == %{"type" => "npc", "id" => 10, "name" => "user"}
  end
end
