defmodule Game.Overworld.SectorTest do
  use Data.ModelCase

  alias Data.Character
  alias Game.Events.RoomEntered
  alias Game.Events.RoomLeft
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
    character = base_character(user)
    npc = %{id: 11, name: "Bandit"}

    %{state: state, user: user, character: character, npc: npc, overworld_id: "1:1,1"}
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
    test "player entering", %{state: state, character: character, overworld_id: overworld_id} do
      {:noreply, state} = Sector.handle_cast({:enter, overworld_id, {:player, character}, :enter}, state)

      assert state.players == [{%{x: 1, y: 1}, character}]
    end

    test "npc entering", %{state: state, npc: npc, overworld_id: overworld_id} do
      {:noreply, state} = Sector.handle_cast({:enter, overworld_id, {:npc, npc}, :enter}, state)

      assert state.npcs == [{%{x: 1, y: 1}, npc}]
    end

    test "sends a notification to users in the same cell", %{state: state, character: character, overworld_id: overworld_id} do
      notify_user = %{base_user() | id: 11}
      notify_character = %{base_character(notify_user) | id: 11}
      Session.Registry.register(notify_character)
      Session.Registry.catch_up()

      state = %{state | players: [{%{x: 1, y: 1}, notify_character}]}

      {:noreply, _state} = Sector.handle_cast({:enter, overworld_id, {:player, character}, :enter}, state)

      assert_receive {:"$gen_cast", {:notify, %RoomEntered{character: {:player, ^character}}}}
    end

    test "does not send notifications to users in different cells", %{state: state, character: character, overworld_id: overworld_id} do
      notify_user = %{base_user() | id: 11}
      notify_character = %{base_character(notify_user) | id: 11}
      Session.Registry.register(notify_character)
      Session.Registry.catch_up()

      state = %{state | players: [{%{x: 1, y: 2}, notify_character}]}

      {:noreply, _state} = Sector.handle_cast({:enter, overworld_id, {:player, character}, :enter}, state)

      refute_receive {:"$gen_cast", {:notify, %RoomEntered{character: {:player, ^character}}}}, 50
    end
  end

  describe "leaving an overworld id" do
    test "player entering", %{state: state, character: character, overworld_id: overworld_id} do
      state = %{state | players: [{%{x: 1, y: 1}, character}, {%{x: 1, y: 1}, %Character{id: 2, name: "Guard"}}]}

      {:noreply, state} = Sector.handle_cast({:leave, overworld_id, {:player, character}, :leave}, state)

      assert state.players == [{%{x: 1, y: 1}, %Character{id: 2, name: "Guard"}}]
    end

    test "npc entering", %{state: state, npc: npc, overworld_id: overworld_id} do
      state = %{state | npcs: [{%{x: 1, y: 1}, npc}, {%{x: 1, y: 1}, %{id: 2, name: "Guard"}}]}

      {:noreply, state} = Sector.handle_cast({:leave, overworld_id, {:npc, npc}, :leave}, state)

      assert state.npcs == [{%{x: 1, y: 1}, %{id: 2, name: "Guard"}}]
    end

    test "sends a notification to users in the same cell", %{state: state, character: character, overworld_id: overworld_id} do
      notify_user = %{base_user() | id: 11}
      notify_character = %{base_character(notify_user) | id: 11}
      Session.Registry.register(notify_character)
      Session.Registry.catch_up()

      state = %{state | players: [{%{x: 1, y: 1}, character}, {%{x: 1, y: 1}, notify_character}]}

      {:noreply, _state} = Sector.handle_cast({:leave, overworld_id, {:player, character}, :leave}, state)

      assert_receive {:"$gen_cast", {:notify, %RoomLeft{character: {:player, ^character}}}}
    end

    test "does not send notifications to users in different cells", %{state: state, character: character, overworld_id: overworld_id} do
      notify_user = %{base_user() | id: 11}
      notify_character = %{base_character(notify_user) | id: 11}
      Session.Registry.register(notify_character)
      Session.Registry.catch_up()

      state = %{state | players: [{%{x: 1, y: 1}, character}, {%{x: 1, y: 2}, notify_character}]}

      {:noreply, _state} = Sector.handle_cast({:leave, overworld_id, {:player, character}, :leave}, state)

      refute_receive {:"$gen_cast", {:notify, %RoomLeft{character: {:player, ^character}}}}, 50
    end
  end

  describe "notify" do
    test "sends notifications to players in the same cell", %{state: state, character: character, overworld_id: overworld_id} do
      notify_user = %{base_user() | id: 11}
      notify_character = %{base_character(notify_user) | id: 11}
      Session.Registry.register(notify_character)
      Session.Registry.catch_up()

      state = %{state | players: [{%{x: 1, y: 1}, character}, {%{x: 1, y: 1}, notify_character}]}

      {:noreply, _state} = Sector.handle_cast({:notify, overworld_id, {:player, character}, {:hi}}, state)

      assert_receive {:"$gen_cast", {:notify, {:hi}}}
    end

    test "does not send notifications to users in different cells", %{state: state, character: character, overworld_id: overworld_id} do
      notify_user = %{base_user() | id: 11}
      notify_character = %{base_character(notify_user) | id: 11}
      Session.Registry.register(notify_character)
      Session.Registry.catch_up()

      state = %{state | players: [{%{x: 1, y: 1}, character}, {%{x: 1, y: 2}, notify_character}]}

      {:noreply, _state} = Sector.handle_cast({:notify, overworld_id, {:player, character}, {:hi}}, state)

      refute_receive {:"$gen_cast", {:notify, {:hi}}}, 50
    end
  end

  describe "update character" do
    test "stores the new information", %{state: state, character: character, overworld_id: overworld_id} do
      character = %{character | name: "Player2"}

      {:noreply, state} = Sector.handle_cast({:update_character, overworld_id, {:player, character}}, state)

      assert [{_cell, %{name: "Player2"}}] = state.players
    end

    test "stores the new information - npc", %{state: state, npc: npc, overworld_id: overworld_id} do
      npc = %{npc | name: "Bandito"}

      {:noreply, state} = Sector.handle_cast({:update_character, overworld_id, {:npc, npc}}, state)

      assert [{_cell, %{name: "Bandito"}}] = state.npcs
    end
  end
end
