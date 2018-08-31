defmodule Game.RoomTest do
  use Data.ModelCase

  alias Data.User
  alias Game.Room

  setup do
    {:ok, user: %{id: 10, name: "user"}, room: %{id: 11}}
  end

  describe "entering a room" do
    test "entering a room", %{user: user, room: room} do
      state = %{room: room, players: [], npcs: []}

      {:noreply, state} = Room.handle_cast({:enter, {:player, user}, :enter}, state)

      assert state.players == [user]
    end
  end

  test "leaving a room - user", %{user: user, room: room} do
    state = %{room: room, players: [user], npcs: []}

    {:noreply, state} = Room.handle_cast({:leave, {:player, user}, :leave}, state)

    assert state.players == []
  end

  test "leaving a room - npc", %{room: room} do
    npc = %{id: 10, name: "Bandit"}
    {:noreply, state} = Room.handle_cast({:leave, {:npc, npc}, :leave}, %{room: room, npcs: [npc], players: []})
    assert state.npcs == []
  end

  test "updating player data" do
    state = %{players: [%User{id: 11, name: "Player"}], npcs: []}

    {:noreply, state} = Room.handle_cast({:update_character, {:player, %User{id: 11, name: "New Name"}}}, state)

    assert state.players == [%User{id: 11, name: "New Name"}]
  end

  test "ignores updates to players not in the list already" do
    state = %{players: [%User{id: 11, name: "Player"}], npcs: []}

    {:noreply, state} = Room.handle_cast({:update_character, {:player, %User{id: 12, name: "New Name"}}}, state)

    assert state.players == [%User{id: 11, name: "Player"}]
  end

  test "updating npc data" do
    {:noreply, state} = Room.handle_cast({:update_character, {:npc, %{id: 10, name: "Name"}}}, %{npcs: [%{id: 10}], players: []})
    assert state.npcs == [%{id: 10, name: "Name"}]
  end

  test "updating npc data - not in the room, does nothing" do
    {:noreply, state} = Room.handle_cast({:update_character, {:npc, %{id: 11, name: "Name"}}}, %{npcs: [%{id: 10}], players: []})

    assert state.npcs == [%{id: 10}]
  end
end
