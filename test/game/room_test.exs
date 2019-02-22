defmodule Game.RoomTest do
  use Data.ModelCase

  alias Game.Room

  setup do
    user = %{base_user() | id: 10, name: "user"}
    character = base_character(user)
    %{user: user, character: character, room: %{id: 11}}
  end

  describe "entering a room" do
    test "entering a room", %{character: character, room: room} do
      state = %{room: room, players: [], npcs: []}

      {:noreply, state} = Room.handle_cast({:enter, character, :enter}, state)

      assert state.players == [character]
    end
  end

  test "leaving a room - user", %{character: character, room: room} do
    state = %{room: room, players: [character], npcs: []}

    {:noreply, state} = Room.handle_cast({:leave, character, :leave}, state)

    assert state.players == []
  end

  test "leaving a room - npc", %{room: room} do
    npc = %{base_npc() | id: 10, name: "Bandit"}
    {:noreply, state} = Room.handle_cast({:leave, npc, :leave}, %{room: room, npcs: [npc], players: []})
    assert state.npcs == []
  end

  test "updating player data" do
    character = base_character(base_user())

    state = %{players: [character], npcs: []}

    {:noreply, state} = Room.handle_cast({:update_character, %{character | name: "New Name"}}, state)

    assert state.players == [%{character | name: "New Name"}]
  end

  test "ignores updates to players not in the list already" do
    state = %{players: [%{id: 11, name: "Player"}], npcs: []}

    {:noreply, state} = Room.handle_cast({:update_character, %{type: "player", id: 12, name: "New Name"}}, state)

    assert state.players == [%{id: 11, name: "Player"}]
  end

  test "updating npc data" do
    {:noreply, state} = Room.handle_cast({:update_character, %{type: "npc", id: 10, name: "Name"}}, %{npcs: [%{id: 10}], players: []})
    assert state.npcs == [%{type: "npc", id: 10, name: "Name"}]
  end

  test "updating npc data - not in the room, does nothing" do
    {:noreply, state} = Room.handle_cast({:update_character, %{type: "npc", id: 11, name: "Name"}}, %{npcs: [%{id: 10}], players: []})

    assert state.npcs == [%{id: 10}]
  end
end
