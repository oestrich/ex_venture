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

    user = %User{id: 10, name: "Player"}
    npc = %{id: 11, name: "Bandit"}

    %{state: state, user: user, npc: npc, overworld_id: "1:1,1"}
  end

  describe "entering an overworld id" do
    test "player entering", %{state: state, user: user, overworld_id: overworld_id} do
      {:noreply, state} = Sector.handle_cast({:enter, overworld_id, {:user, user}, :enter}, state)

      assert state.players == [{%{x: 1, y: 1}, user}]
    end

    test "npc entering", %{state: state, npc: npc, overworld_id: overworld_id} do
      {:noreply, state} = Sector.handle_cast({:enter, overworld_id, {:npc, npc}, :enter}, state)

      assert state.npcs == [{%{x: 1, y: 1}, npc}]
    end

    test "sends a notification to users in the same cell", %{state: state, user: user, overworld_id: overworld_id} do
      notify_user = %User{id: 11}
      Session.Registry.register(notify_user)

      state = %{state | players: [{%{x: 1, y: 1}, notify_user}]}

      {:noreply, _state} = Sector.handle_cast({:enter, overworld_id, {:user, user}, :enter}, state)

      assert_receive {:"$gen_cast", {:notify, {"room/entered", {{:user, ^user}, :enter}}}}
    end

    test "does not send notifications to users in different cells", %{state: state, user: user, overworld_id: overworld_id} do
      notify_user = %User{id: 11}
      Session.Registry.register(notify_user)

      state = %{state | players: [{%{x: 1, y: 2}, notify_user}]}

      {:noreply, _state} = Sector.handle_cast({:enter, overworld_id, {:user, user}, :enter}, state)

      refute_receive {:"$gen_cast", {:notify, {"room/entered", {{:user, ^user}, :enter}}}}, 50
    end
  end

  describe "leaving an overworld id" do
    test "player entering", %{state: state, user: user, overworld_id: overworld_id} do
      state = %{state | players: [{%{x: 1, y: 1}, user}, {%{x: 1, y: 1}, %User{id: 2, name: "Guard"}}]}

      {:noreply, state} = Sector.handle_cast({:leave, overworld_id, {:user, user}, :leave}, state)

      assert state.players == [{%{x: 1, y: 1}, %User{id: 2, name: "Guard"}}]
    end

    test "npc entering", %{state: state, npc: npc, overworld_id: overworld_id} do
      state = %{state | npcs: [{%{x: 1, y: 1}, npc}, {%{x: 1, y: 1}, %{id: 2, name: "Guard"}}]}

      {:noreply, state} = Sector.handle_cast({:leave, overworld_id, {:npc, npc}, :leave}, state)

      assert state.npcs == [{%{x: 1, y: 1}, %{id: 2, name: "Guard"}}]
    end

    test "sends a notification to users in the same cell", %{state: state, user: user, overworld_id: overworld_id} do
      notify_user = %User{id: 11}
      Session.Registry.register(notify_user)

      state = %{state | players: [{%{x: 1, y: 1}, user}, {%{x: 1, y: 1}, notify_user}]}

      {:noreply, _state} = Sector.handle_cast({:leave, overworld_id, {:user, user}, :leave}, state)

      assert_receive {:"$gen_cast", {:notify, {"room/leave", {{:user, ^user}, :leave}}}}
    end

    test "does not send notifications to users in different cells", %{state: state, user: user, overworld_id: overworld_id} do
      notify_user = %User{id: 11}
      Session.Registry.register(notify_user)

      state = %{state | players: [{%{x: 1, y: 1}, user}, {%{x: 1, y: 2}, notify_user}]}

      {:noreply, _state} = Sector.handle_cast({:leave, overworld_id, {:user, user}, :leave}, state)

      refute_receive {:"$gen_cast", {:notify, {"room/leave", {{:user, ^user}, :leave}}}}, 50
    end
  end

  describe "notify" do
    test "sends notifications to players in the same cell", %{state: state, user: user, overworld_id: overworld_id} do
      notify_user = %User{id: 11}
      Session.Registry.register(notify_user)

      state = %{state | players: [{%{x: 1, y: 1}, user}, {%{x: 1, y: 1}, notify_user}]}

      {:noreply, _state} = Sector.handle_cast({:notify, overworld_id, {:user, user}, {:hi}}, state)

      assert_receive {:"$gen_cast", {:notify, {:hi}}}
    end

    test "does not send notifications to users in different cells", %{state: state, user: user, overworld_id: overworld_id} do
      notify_user = %User{id: 11}
      Session.Registry.register(notify_user)

      state = %{state | players: [{%{x: 1, y: 1}, user}, {%{x: 1, y: 2}, notify_user}]}

      {:noreply, _state} = Sector.handle_cast({:notify, overworld_id, {:user, user}, {:hi}}, state)

      refute_receive {:"$gen_cast", {:notify, {:hi}}}, 50
    end
  end

  describe "say" do
    test "sends a say message", %{state: state, user: user, overworld_id: overworld_id} do
      notify_user = %User{id: 11}
      Session.Registry.register(notify_user)

      state = %{state | players: [{%{x: 1, y: 1}, user}, {%{x: 1, y: 1}, notify_user}]}

      {:noreply, _state} = Sector.handle_cast({:say, overworld_id, {:user, user}, "hi"}, state)

      assert_receive {:"$gen_cast", {:notify, {"room/heard", "hi"}}}
    end
  end

  describe "emote" do
    test "sends an emote message", %{state: state, user: user, overworld_id: overworld_id} do
      notify_user = %User{id: 11}
      Session.Registry.register(notify_user)

      state = %{state | players: [{%{x: 1, y: 1}, user}, {%{x: 1, y: 1}, notify_user}]}

      {:noreply, _state} = Sector.handle_cast({:emote, overworld_id, {:user, user}, "hi"}, state)

      assert_receive {:"$gen_cast", {:notify, {"room/heard", "hi"}}}
    end
  end
end
