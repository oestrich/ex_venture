defmodule Game.RoomTest do
  use Data.ModelCase

  alias Game.Room

  setup do
    {:ok, user: %{id: 10, name: "user"}}
  end

  test "entering a room", %{user: user} do
    {:noreply, state} = Room.handle_cast({:enter, {:user, :session, user}}, %{players: []})
    assert state.players == [{:user, :session, user}]
  end

  test "leaving a room - user", %{user: user} do
    {:noreply, state} = Room.handle_cast({:leave, {:user, :session, user}}, %{players: [{:user, :session, user}]})
    assert state.players == []
  end

  test "leaving a room - npc" do
    npc = %{id: 10, name: "Bandit"}
    {:noreply, state} = Room.handle_cast({:leave, {:npc, npc}}, %{npcs: [npc]})
    assert state.npcs == []
  end
end
