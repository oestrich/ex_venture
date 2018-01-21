defmodule Game.RoomTest do
  use Data.ModelCase

  alias Game.Room
  alias Game.Message

  setup do
    {:ok, user: %{id: 10, name: "user"}, room: %{id: 11}}
  end

  test "entering a room", %{user: user, room: room} do
    {:noreply, state} = Room.handle_cast({:enter, {:user, :session, user}, :enter}, %{room: room, players: [], npcs: []})
    assert state.players == [{:user, :session, user}]
  end

  test "entering a room sends notifications - user", %{user: user, room: room} do
    {:noreply, _state} = Room.handle_cast({:enter, {:user, :session, user}, :enter}, %{room: room, players: [{:user, self(), user}], npcs: []})
    assert_receive {:"$gen_cast", {:notify, {"room/entered", {{:user, ^user}, :enter}}}}
  end

  test "entering a room sends notifications - npc", %{user: user, room: room} do
    npc = %{id: 10, name: "Bandit"}
    {:noreply, _state} = Room.handle_cast({:enter, {:npc, npc}, :enter}, %{room: room, players: [{:user, self(), user}], npcs: []})
    assert_receive {:"$gen_cast", {:notify, {"room/entered", {{:npc, ^npc}, :enter}}}}
  end

  test "leaving a room - user", %{user: user, room: room} do
    state = %{room: room, players: [{:user, :session, user}], npcs: []}
    {:noreply, state} = Room.handle_cast({:leave, {:user, :session, user}, :leave}, state)
    assert state.players == []
  end

  test "leaving a room sends notifications - user", %{user: user, room: room} do
    state = %{room: room, players: [{:user, self(), %{id: 11}}], npcs: []}
    {:noreply, _state} = Room.handle_cast({:leave, {:user, :session, user}, :leave}, state)
    assert_receive {:"$gen_cast", {:notify, {"room/leave", {{:user, ^user}, :leave}}}}
  end

  test "leaving a room sends notifications - npc", %{user: user, room: room} do
    npc = %{id: 10, name: "Bandit"}
    {:noreply, _state} = Room.handle_cast({:leave, {:npc, npc}, :leave}, %{room: room, npcs: [npc], players: [{:user, self(), user}]})
    assert_receive {:"$gen_cast", {:notify, {"room/leave", {{:npc, ^npc}, :leave}}}}
  end

  test "leaving a room - npc", %{room: room} do
    npc = %{id: 10, name: "Bandit"}
    {:noreply, state} = Room.handle_cast({:leave, {:npc, npc}, :leave}, %{room: room, npcs: [npc], players: []})
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

  test "updating npc data - not in the room, considers it an 'enter'" do
    {:noreply, state} = Room.handle_cast({:update_character, {:npc, %{id: 11, name: "Name"}}}, %{npcs: [%{id: 10}], players: []})

    assert state.npcs == [%{id: 10}]
    assert_receive {:"$gen_cast", {:enter, {:npc, %{id: 11}}}}
  end
end
