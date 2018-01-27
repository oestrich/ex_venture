defmodule Game.RoomTest do
  use Data.ModelCase

  alias Data.User
  alias Game.Message
  alias Game.Room
  alias Game.Session

  setup do
    {:ok, user: %{id: 10, name: "user"}, room: %{id: 11}}
  end

  describe "entering a room" do
    test "entering a room", %{user: user, room: room} do
      state = %{room: room, players: [], npcs: []}

      {:noreply, state} = Room.handle_cast({:enter, {:user, user}, :enter}, state)

      assert state.players == [user]
    end

    test "entering a room sends notifications - user", %{user: user, room: room} do
      notify_user = %User{id: 11}
      Session.Registry.register(notify_user)

      state = %{room: room, players: [notify_user], npcs: []}

      {:noreply, _state} = Room.handle_cast({:enter, {:user, user}, :enter}, state)

      assert_receive {:"$gen_cast", {:notify, {"room/entered", {{:user, ^user}, :enter}}}}
    end

    test "entering a room sends notifications - npc", %{room: room} do
      notify_user = %User{id: 11}
      Session.Registry.register(notify_user)

      npc = %{id: 10, name: "Bandit"}

      state = %{room: room, players: [notify_user], npcs: []}
      {:noreply, _state} = Room.handle_cast({:enter, {:npc, npc}, :enter}, state)

      assert_receive {:"$gen_cast", {:notify, {"room/entered", {{:npc, ^npc}, :enter}}}}
    end
  end

  test "leaving a room - user", %{user: user, room: room} do
    state = %{room: room, players: [user], npcs: []}

    {:noreply, state} = Room.handle_cast({:leave, {:user, user}, :leave}, state)

    assert state.players == []
  end

  test "leaving a room sends notifications - user", %{user: user, room: room} do
    notify_user = %User{id: 11}
    Session.Registry.register(notify_user)

    state = %{room: room, players: [notify_user], npcs: []}

    {:noreply, _state} = Room.handle_cast({:leave, {:user, user}, :leave}, state)

    assert_receive {:"$gen_cast", {:notify, {"room/leave", {{:user, ^user}, :leave}}}}
  end

  test "leaving a room sends notifications - npc", %{room: room} do
    notify_user = %User{id: 11}
    Session.Registry.register(notify_user)

    npc = %{id: 10, name: "Bandit"}
    state = %{room: room, npcs: [npc], players: [notify_user]}

    {:noreply, _state} = Room.handle_cast({:leave, {:npc, npc}, :leave}, state)

    assert_receive {:"$gen_cast", {:notify, {"room/leave", {{:npc, ^npc}, :leave}}}}
  end

  test "leaving a room - npc", %{room: room} do
    npc = %{id: 10, name: "Bandit"}
    {:noreply, state} = Room.handle_cast({:leave, {:npc, npc}, :leave}, %{room: room, npcs: [npc], players: []})
    assert state.npcs == []
  end

  test "emoting", %{user: user} do
    notify_user = %User{id: 11}
    Session.Registry.register(notify_user)

    message = Message.emote(user, "emote")
    state = %{players: [notify_user], npcs: []}

    {:noreply, _state} = Room.handle_cast({:emote, {:user, user}, message}, state)

    assert_received {:"$gen_cast", {:notify, {"room/heard", %Message{message: "emote"}}}}
  end

  test "updating player data" do
    state = %{players: [%User{id: 11, name: "Player"}], npcs: []}

    {:noreply, state} = Room.handle_cast({:update_character, {:user, %User{id: 11, name: "New Name"}}}, state)

    assert state.players == [%User{id: 11, name: "New Name"}]
  end

  test "ignores updates to players not in the list already" do
    state = %{players: [%User{id: 11, name: "Player"}], npcs: []}

    {:noreply, state} = Room.handle_cast({:update_character, {:user, %User{id: 12, name: "New Name"}}}, state)

    assert state.players == [%User{id: 11, name: "Player"}]
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
