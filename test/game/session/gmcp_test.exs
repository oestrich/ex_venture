defmodule Game.Session.GMCPTest do
  use GenServerCase

  @socket Test.Networking.Socket

  alias Game.Session.GMCP

  setup do
    %{socket: :socket}
  end

  test "character enters - player", state do
    GMCP.character_enter(state, {:player, %{id: 10, name: "user"}})

    assert [{:socket, "Room.Character.Enter", json}] = @socket.get_push_gmcps()
    assert Poison.decode!(json) == %{"type" => "player", "id" => 10, "name" => "user"}
  end

  test "character enters - npc", state do
    GMCP.character_enter(state, {:npc, %{id: 10, name: "Bandit"}})

    assert [{:socket, "Room.Character.Enter", json}] = @socket.get_push_gmcps()
    assert Poison.decode!(json) == %{"type" => "npc", "id" => 10, "name" => "Bandit"}
  end

  test "character leaves - player", state do
    GMCP.character_leave(state, {:player, %{id: 10, name: "user"}})

    assert [{:socket, "Room.Character.Leave", json}] = @socket.get_push_gmcps()
    assert Poison.decode!(json) == %{"type" => "player", "id" => 10, "name" => "user"}
  end

  test "character leaves - npc", state do
    GMCP.character_leave(state, {:npc, %{id: 10, name: "user"}})

    assert [{:socket, "Room.Character.Leave", json}] = @socket.get_push_gmcps()
    assert Poison.decode!(json) == %{"type" => "npc", "id" => 10, "name" => "user"}
  end
end
