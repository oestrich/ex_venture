defmodule Game.Overworld.SectorTest do
  use Data.ModelCase

  alias Data.User
  alias Game.Overworld.Sector
  alias Game.Session

  setup do
    state = %{
      zone_id: 1,
      sector: "0-0",
      players: [],
      npcs: [],
    }

    user = base_user()
    npc = %{id: 11, name: "Bandit"}

    %{state: state, user: user, npc: npc, overworld_id: "1:1,1"}
  end

  describe "looking" do
    test "looks at the current overworld", %{state: state, overworld_id: overworld_id} do
      Cachex.put(:zones, 1, %{id: 1, name: "Zone", overworld_map: []})

      {:reply, {:ok, environment}, _state} = Sector.handle_call({:look, overworld_id}, nil, state)

      assert environment.x == 1
      assert environment.y == 1
      assert environment.zone == "Zone"
    end
  end

  describe "entering an overworld id" do
    test "player entering", %{state: state, user: user, overworld_id: overworld_id} do
      {:noreply, state} = Sector.handle_cast({:enter, overworld_id, {:player, user}, :enter}, state)

      assert state.players == [{%{x: 1, y: 1}, user}]
    end

    test "npc entering", %{state: state, npc: npc, overworld_id: overworld_id} do
      {:noreply, state} = Sector.handle_cast({:enter, overworld_id, {:npc, npc}, :enter}, state)

      assert state.npcs == [{%{x: 1, y: 1}, npc}]
    end

    test "sends a notification to users in the same cell", %{state: state, user: user, overworld_id: overworld_id} do
      notify_user = %{base_user() | id: 11}
      Session.Registry.register(notify_user)
      Session.Registry.catch_up()

      state = %{state | players: [{%{x: 1, y: 1}, notify_user}]}

      {:noreply, _state} = Sector.handle_cast({:enter, overworld_id, {:player, user}, :enter}, state)

      assert_receive {:"$gen_cast", {:notify, {"room/entered", {{:player, ^user}, :enter}}}}
    end

    test "does not send notifications to users in different cells", %{state: state, user: user, overworld_id: overworld_id} do
      notify_user = %{base_user() | id: 11}
      Session.Registry.register(notify_user)
      Session.Registry.catch_up()

      state = %{state | players: [{%{x: 1, y: 2}, notify_user}]}

      {:noreply, _state} = Sector.handle_cast({:enter, overworld_id, {:player, user}, :enter}, state)

      refute_receive {:"$gen_cast", {:notify, {"room/entered", {{:player, ^user}, :enter}}}}, 50
    end
  end

  describe "leaving an overworld id" do
    test "player entering", %{state: state, user: user, overworld_id: overworld_id} do
      state = %{state | players: [{%{x: 1, y: 1}, user}, {%{x: 1, y: 1}, %User{id: 2, name: "Guard"}}]}

      {:noreply, state} = Sector.handle_cast({:leave, overworld_id, {:player, user}, :leave}, state)

      assert state.players == [{%{x: 1, y: 1}, %User{id: 2, name: "Guard"}}]
    end

    test "npc entering", %{state: state, npc: npc, overworld_id: overworld_id} do
      state = %{state | npcs: [{%{x: 1, y: 1}, npc}, {%{x: 1, y: 1}, %{id: 2, name: "Guard"}}]}

      {:noreply, state} = Sector.handle_cast({:leave, overworld_id, {:npc, npc}, :leave}, state)

      assert state.npcs == [{%{x: 1, y: 1}, %{id: 2, name: "Guard"}}]
    end

    test "sends a notification to users in the same cell", %{state: state, user: user, overworld_id: overworld_id} do
      notify_user = %{base_user() | id: 11}
      Session.Registry.register(notify_user)
      Session.Registry.catch_up()

      state = %{state | players: [{%{x: 1, y: 1}, user}, {%{x: 1, y: 1}, notify_user}]}

      {:noreply, _state} = Sector.handle_cast({:leave, overworld_id, {:player, user}, :leave}, state)

      assert_receive {:"$gen_cast", {:notify, {"room/leave", {{:player, ^user}, :leave}}}}
    end

    test "does not send notifications to users in different cells", %{state: state, user: user, overworld_id: overworld_id} do
      notify_user = %{base_user() | id: 11}
      Session.Registry.register(notify_user)
      Session.Registry.catch_up()

      state = %{state | players: [{%{x: 1, y: 1}, user}, {%{x: 1, y: 2}, notify_user}]}

      {:noreply, _state} = Sector.handle_cast({:leave, overworld_id, {:player, user}, :leave}, state)

      refute_receive {:"$gen_cast", {:notify, {"room/leave", {{:player, ^user}, :leave}}}}, 50
    end
  end

  describe "notify" do
    test "sends notifications to players in the same cell", %{state: state, user: user, overworld_id: overworld_id} do
      notify_user = %{base_user() | id: 11}
      Session.Registry.register(notify_user)
      Session.Registry.catch_up()

      state = %{state | players: [{%{x: 1, y: 1}, user}, {%{x: 1, y: 1}, notify_user}]}

      {:noreply, _state} = Sector.handle_cast({:notify, overworld_id, {:player, user}, {:hi}}, state)

      assert_receive {:"$gen_cast", {:notify, {:hi}}}
    end

    test "does not send notifications to users in different cells", %{state: state, user: user, overworld_id: overworld_id} do
      notify_user = %{base_user() | id: 11}
      Session.Registry.register(notify_user)
      Session.Registry.catch_up()

      state = %{state | players: [{%{x: 1, y: 1}, user}, {%{x: 1, y: 2}, notify_user}]}

      {:noreply, _state} = Sector.handle_cast({:notify, overworld_id, {:player, user}, {:hi}}, state)

      refute_receive {:"$gen_cast", {:notify, {:hi}}}, 50
    end
  end

  describe "say" do
    test "sends a say message", %{state: state, user: user, overworld_id: overworld_id} do
      notify_user = %{base_user() | id: 11}
      Session.Registry.register(notify_user)
      Session.Registry.catch_up()

      state = %{state | players: [{%{x: 1, y: 1}, user}, {%{x: 1, y: 1}, notify_user}]}

      {:noreply, _state} = Sector.handle_cast({:say, overworld_id, {:player, user}, "hi"}, state)

      assert_receive {:"$gen_cast", {:notify, {"room/heard", "hi"}}}
    end
  end

  describe "emote" do
    test "sends an emote message", %{state: state, user: user, overworld_id: overworld_id} do
      notify_user = %{base_user() | id: 11}
      Session.Registry.register(notify_user)
      Session.Registry.catch_up()

      state = %{state | players: [{%{x: 1, y: 1}, user}, {%{x: 1, y: 1}, notify_user}]}

      {:noreply, _state} = Sector.handle_cast({:emote, overworld_id, {:player, user}, "hi"}, state)

      assert_receive {:"$gen_cast", {:notify, {"room/heard", "hi"}}}
    end
  end

  describe "update character" do
    test "stores the new information", %{state: state, user: user, overworld_id: overworld_id} do
      user = %{user | name: "Player2"}

      {:noreply, state} = Sector.handle_cast({:update_character, overworld_id, {:player, user}}, state)

      assert [{_cell, %{name: "Player2"}}] = state.players
    end

    test "stores the new information - npc", %{state: state, npc: npc, overworld_id: overworld_id} do
      npc = %{npc | name: "Bandito"}

      {:noreply, state} = Sector.handle_cast({:update_character, overworld_id, {:npc, npc}}, state)

      assert [{_cell, %{name: "Bandito"}}] = state.npcs
    end
  end
end
