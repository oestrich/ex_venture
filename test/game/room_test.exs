defmodule Game.RoomTest do
  use Data.ModelCase

  alias Game.Room
  alias Game.Message

  setup do
    {:ok, user: %{id: 10, name: "user"}, room: %{id: 11}}
  end

  test "entering a room", %{user: user, room: room} do
    {:noreply, state} = Room.handle_cast({:enter, {:user, :session, user}}, %{room: room, players: []})
    assert state.players == [{:user, :session, user}]
  end

  test "entering a room pushes gmcp data - user", %{user: user, room: room} do
    {:noreply, _state} = Room.handle_cast({:enter, {:user, :session, user}}, %{room: room, players: [{:user, self(), user}]})
    assert_receive {:"$gen_cast", {:gmcp, "Room.Character.Enter", %{type: :player, id: 10, name: "user"}}}
  end

  test "entering a room pushes gmcp data - npc", %{user: user, room: room} do
    {:noreply, _state} = Room.handle_cast({:enter, {:npc, user}}, %{room: room, players: [{:user, self(), user}], npcs: []})
    assert_receive {:"$gen_cast", {:gmcp, "Room.Character.Enter", %{type: :npc, id: 10, name: "user"}}}
  end

  test "leaving a room - user", %{user: user, room: room} do
    {:noreply, state} = Room.handle_cast({:leave, {:user, :session, user}}, %{room: room, players: [{:user, :session, user}]})
    assert state.players == []
  end

  test "leaving a room sends a gmcp message - npc", %{user: user, room: room} do
    npc = %{id: 10, name: "Bandit"}
    {:noreply, _state} = Room.handle_cast({:leave, {:npc, npc}}, %{room: room, npcs: [npc], players: [{:user, self(), user}]})
    assert_receive {:"$gen_cast", {:gmcp, "Room.Character.Leave", %{type: :npc, id: 10, name: "Bandit"}}}
  end

  test "leaving a room sends a gmcp message - user", %{user: user, room: room} do
    {:noreply, _state} = Room.handle_cast({:leave, {:user, :session, user}}, %{room: room, players: [{:user, self(), %{id: 11}}]})
    assert_receive {:"$gen_cast", {:gmcp, "Room.Character.Leave", %{type: :player, id: 10, name: "user"}}}
  end

  test "leaving a room - npc", %{room: room} do
    npc = %{id: 10, name: "Bandit"}
    {:noreply, state} = Room.handle_cast({:leave, {:npc, npc}}, %{room: room, npcs: [npc], players: []})
    assert state.npcs == []
  end

  test "emoting", %{user: user} do
    message = Message.emote(user, "emote")
    {:noreply, _state} = Room.handle_cast({:emote, :session, message}, %{players: [{:user, self(), :user}], npcs: []})
    assert_received {:"$gen_cast", {:echo, "{blue}user{/blue} {green}emote{/green}"}}
  end

  test "updating player data" do
    {:noreply, state} = Room.handle_cast({:update_character, {:user, self(), :new_user}}, %{players: [{:user, self(), :user}], npcs: []})
    assert state.players == [{:user, self(), :new_user}]
  end

  test "ignores updates to players not in the list already" do
    {:noreply, state} = Room.handle_cast({:update_character, {:user, self(), :new_user}}, %{players: [{:user, :pid, :user}], npcs: []})
    assert state.players == [{:user, :pid, :user}]
  end

  test "updating npc data" do
    {:noreply, state} = Room.handle_cast({:update_character, {:npc, %{id: 10, name: "Name"}}}, %{npcs: [%{id: 10}], players: []})
    assert state.npcs == [%{id: 10, name: "Name"}]
  end

  test "ignores updates to npcs not in the list already" do
    {:noreply, state} = Room.handle_cast({:update_character, {:npc, %{id: 11, name: "Name"}}}, %{npcs: [%{id: 10}], players: []})
    assert state.npcs == [%{id: 10}]
  end
end
