defmodule Game.NPC.EventsTest do
  use Data.ModelCase

  @room Test.Game.Room

  alias Game.Channel
  alias Game.Door
  alias Game.Message
  alias Game.NPC.Events
  alias Game.NPC.State
  alias Game.Session.Registry

  setup do
    @room.clear_says()
  end

  describe "character/died" do
    setup do
      npc = %{id: 1, name: "Mayor", events: [], stats: base_stats()}
      user = %{id: 2, name: "Player"}

      state = %State{room_id: 1, npc: npc, target: nil}

      @room._room()
      |> Map.put(:npcs, [npc])
      |> Map.put(:players, [%{id: 1, name: "Player"}])
      |> @room.set_room()

      event = {"character/died", {:user, user}, :character, {:npc, npc}}

      %{state: state, event: event}
    end

    test "clears the target if they were targetting the character", %{state: state, event: event} do
      state = %{state | target: {:user, 2}}
      {:update, state} = Events.act_on(state, event)
      assert is_nil(state.target)
    end

    test "does nothing if the target does not match", %{state: state, event: event} do
      :ok = Events.act_on(state, event)
    end
  end

  describe "combat/tick" do
    setup do
      event = %{
        type: "combat/tick",
        action: %{
          type: "target/effects",
          delay: 0.01,
          text: "A skill was used",
          weight: 10,
          effects: [
            %{kind: "damage", type: :slashing, amount: 10},
          ],
        },
      }

      npc = %{id: 1, name: "Mayor", events: [event], stats: base_stats()}
      state = %State{room_id: 1, npc: npc}

      @room._room()
      |> Map.put(:npcs, [npc])
      |> Map.put(:players, [%{id: 1, name: "Player"}])
      |> @room.set_room()

      event = {"combat/tick"}

      %{state: state, event: event}
    end

    test "does nothing if no target", %{state: state, event: event} do
      :ok = Events.act_on(state, event)

      refute_receive {:"$gen_cast", {:notify, {"combat/tick"}}}
    end

    test "does nothing if target no longer in the room, and removes target", %{state: state, event: event} do
      state = %State{state | target: {:user, 2}}

      {:update, state} = Events.act_on(state, event)

      assert is_nil(state.target)

      refute_receive {:"$gen_cast", {:notify, {"combat/tick"}}}
    end

    test "calculates the effects and then applies them to the target", %{state: state, event: event} do
      Registry.register(%{id: 1})
      state = %State{state | target: {:user, 1}}

      {:update, state} = Events.act_on(state, event)

      assert state.target

      assert_receive {:"$gen_cast", {:apply_effects, [%{amount: 15, kind: "damage", type: :slashing}], {:npc, _}, "A skill was used"}}
      assert_receive {:"$gen_cast", {:notify, {"combat/tick"}}}
    end
  end

  describe "room/entered" do
    test "say something to the room when a player enters it" do
      npc = %{id: 1, name: "Mayor", events: [%{type: "room/entered", action: %{type: "say", message: "Hello"}}]}
      state = %State{room_id: 1, npc: npc}

      {:update, ^state} = Events.act_on(state, {"room/entered", {{:user, %{name: "Player"}}, :enter}})

      [{_, message}] = @room.get_says()
      assert message.message == "Hello"
    end

    test "do nothing when an NPC enters the room" do
      npc = %{id: 1, name: "Mayor", events: [%{type: "room/entered", action: %{type: "say", message: "Hello"}}]}
      state = %State{room_id: 1, npc: npc}

      {:update, ^state} = Events.act_on(state, {"room/entered", {{:npc, %{name: "Bandit"}}, :enter}})

      assert @room.get_says() |> length() == 0
    end

    test "target the player when they entered" do
      Registry.register(%{id: 2})

      npc = %{id: 1, name: "Mayor", events: [%{type: "room/entered", action: %{type: "target"}}]}
      state = %State{room_id: 1, npc: npc}

      {:update, state} = Events.act_on(state, {"room/entered", {{:user, %{id: 2, name: "Player"}}, :enter}})
      assert state.target == {:user, 2}

      assert_received {:"$gen_cast", {:targeted, {:npc, %{id: 1}}}}
    end
  end

  describe "room/leave" do
    test "clears the target when player leaves" do
      npc = %{id: 1, name: "Mayor", events: []}
      state = %State{room_id: 1, npc: npc, target: {:user, 2}}

      {:update, state} = Events.act_on(state, {"room/leave", {{:user, %{id: 2, name: "Player"}}, :leave}})
      assert is_nil(state.target)
    end

    test "does not touch the target if another player leaves" do
      npc = %{id: 1, name: "Mayor", events: []}
      state = %State{room_id: 1, npc: npc, target: {:user, 2}}

      :ok = Events.act_on(state, {"room/leave", {{:user, %{id: 3, name: "Player"}}, :leave}})
    end
  end

  describe "room/heard" do
    test "matches condition" do
      npc = %{id: 1, name: "Mayor", events: [%{type: "room/heard", condition: %{regex: "hi"}, action: %{type: "say", message: "Hello"}}]}
      state = %State{room_id: 1, npc: npc}

      :ok = Events.act_on(state, {"room/heard", Message.new(%{name: "name"}, "Hi")})

      [{_, message}] = @room.get_says()
      assert message.message == "Hello"
    end

    test "does not match condition" do
      npc = %{id: 1, name: "Mayor", events: [%{type: "room/heard", condition: %{regex: "hi"}, action: %{type: "say", message: "Hello"}}]}
      state = %State{room_id: 1, npc: npc}

      :ok = Events.act_on(state, {"room/heard", Message.new(%{name: "name"}, "Howdy")})

      assert [] = @room.get_says()
    end

    test "no condition" do
      npc = %{id: 1, name: "Mayor", events: [%{type: "room/heard", condition: nil, action: %{type: "say", message: "Hello"}}]}
      state = %State{room_id: 1, npc: npc}

      :ok = Events.act_on(state, {"room/heard", Message.new(%{name: "name"}, "Howdy")})

      [{_, message}] = @room.get_says()
      assert message.message == "Hello"
    end

    test "does not consider it's own messages" do
      npc = %{id: 1, name: "Mayor", events: [%{type: "room/heard", condition: nil, action: %{type: "say", message: "Hello"}}]}
      state = %State{room_id: 1, npc: npc}

      :ok = Events.act_on(state, {"room/heard", Message.npc_say(npc, "Hello")})

      assert [] = @room.get_says()
    end
  end

  describe "ticking events" do
    test "adds UUIDs" do
      events = [
        %{type: "tick"},
        %{type: "room/heard"},
        %{type: "tick"},
      ]

      assert [%{id: _}, %{id: _}] = Events.instantiate_ticks(events)
    end

    test "calculates the delay" do
      event = %{
        type: "tick",
        action: %{
          chance: 50,
          wait: 10,
        },
      }

      assert Events.calculate_delay(event, Test.NPCDelay) == 40
    end
  end

  describe "tick - move" do
    setup do
      event = %{
        type: "tick",
        action: %{
          type: "move",
          max_distance: 3,
          chance: 50,
          wait: 10,
        },
      }

      npc = %{id: 1, name: "Mayor", events: [event], stats: base_stats()}
      state = %State{room_id: 1, npc: npc, npc_spawner: %{room_id: 1}}

      @room._room()
      |> Map.put(:id, 1)
      |> Map.put(:y, 1)
      |> Map.put(:exits, [%{north_id: 2, south_id: 1, has_door: false}])
      |> @room.set_room(multiple: true)

      @room._room()
      |> Map.put(:id, 2)
      |> Map.put(:y, 0)
      |> Map.put(:exits, [%{north_id: 2, south_id: 1, has_door: false}])
      |> @room.set_room(multiple: true)

      @room.clear_enters()
      @room.clear_leaves()
      start_and_clear_doors()

      %{state: state, event: event}
    end

    # random number < chance, move
    # leave current room, send clearing targets, enter new room, save state
    test "moves to a random exit", %{state: state, event: event} do
      state = Events.act_on_tick(state, event)

      assert state.room_id == 2

      assert [{2, {:npc, _npc}, _reason}] = @room.get_enters()
      assert [{1, {:npc, _npc}, _reason}] = @room.get_leaves()
    end

    test "does not pick a room that would go further away than the max distance", %{state: state, event: event} do
      @room._room()
      |> Map.put(:id, 2)
      |> Map.put(:y, 7)
      |> Map.put(:exits, [%{north_id: 2, south_id: 1, has_door: false}])
      |> @room.set_room(multiple: true)

      state = Events.act_on_tick(state, event)

      assert state.room_id == 1

      assert [] = @room.get_enters()
      assert [] = @room.get_leaves()
    end

    test "won't move if it has a target", %{state: state, event: event} do
      state = %{state | target: {:npc, 1}}

      state = Events.act_on_tick(state, event)

      assert state.room_id == 1
    end

    test "does nothing if the NPC has no health", %{state: state, event: event} do
      stats = %{state.npc.stats | health: 0}
      npc = %{state.npc | stats: stats}
      state = %{state | npc: npc}

      state = Events.act_on_tick(state, event)

      assert state.room_id == 1
    end

    test "will send a `room/entered` for each player already in the room", %{state: state, event: event} do
      @room._room()
      |> Map.put(:id, 2)
      |> Map.put(:y, 0)
      |> Map.put(:players, [%{id: 10}])
      |> Map.put(:exits, [%{north_id: 2, south_id: 1, has_door: false}])
      |> @room.set_room(multiple: true)

      state = Events.act_on_tick(state, event)

      assert state.room_id == 2

      assert_receive {:"$gen_cast", {:notify, {"room/entered", {{:user, %{id: 10}}, :enter}}}}
    end

    test "will not move if the door is closed", %{state: state, event: event} do
      room_exit = %{id: 10, north_id: 2, south_id: 1, has_door: true}

      @room._room()
      |> Map.put(:id, 1)
      |> Map.put(:y, 1)
      |> Map.put(:exits, [room_exit])
      |> @room.set_room(multiple: true)

      @room._room()
      |> Map.put(:id, 2)
      |> Map.put(:y, 0)
      |> Map.put(:exits, [room_exit])
      |> @room.set_room(multiple: true)

      Door.load(room_exit)
      Door.set(room_exit, "closed")

      state = Events.act_on_tick(state, event)

      assert state.room_id == 1

      assert [] = @room.get_enters()
      assert [] = @room.get_leaves()
    end

    test "will not move if the chosen room is in a new zone", %{state: state, event: event} do
      @room._room()
      |> Map.put(:id, 2)
      |> Map.put(:zone_id, 2)
      |> Map.put(:exits, [%{north_id: 2, south_id: 1, has_door: false}])
      |> @room.set_room(multiple: true)

      state = Events.act_on_tick(state, event)

      assert state.room_id == 1

      assert [] = @room.get_enters()
      assert [] = @room.get_leaves()
    end

    test "room is not too far if old.x - new.x <= max and old.y - new.y <= max" do
      action = %{max_distance: 3}
      old_room = %{x: 0, y: 0}
      new_room = %{x: 1, y: 1}

      assert Events.under_maximum_move?(action, old_room, new_room)
    end

    test "room is too far if old.x - new.x > max" do
      action = %{max_distance: 3}
      old_room = %{x: 0, y: 0}
      new_room = %{x: 4, y: 1}

      refute Events.under_maximum_move?(action, old_room, new_room)
    end

    test "room is too far if old.y - new.y > max" do
      action = %{max_distance: 3}
      old_room = %{x: 0, y: 0}
      new_room = %{x: 1, y: 4}

      refute Events.under_maximum_move?(action, old_room, new_room)
    end
  end

  describe "tick - emote" do
    setup do
      event = %{
        type: "tick",
        action: %{
          type: "emote",
          message: "fidgets",
          chance: 50,
          wait: 10,
        },
      }

      @room.clear_emotes()

      npc = %{id: 1, name: "Mayor", events: [event], stats: base_stats()}
      state = %State{room_id: 1, npc: npc, npc_spawner: %{room_id: 1}}

      %{state: state, event: event}
    end

    test "will emote to the room", %{state: state, event: event} do
      assert Events.act_on_tick(state, event)

      [{_, message}] = @room.get_emotes()
      assert message.message == "fidgets"
    end
  end

  describe "tick - say" do
    setup do
      event = %{
        type: "tick",
        action: %{
          type: "say",
          message: "Can I help you?",
          chance: 50,
          wait: 10,
        },
      }

      @room.clear_says()
      @room.clear_emotes()

      npc = %{id: 1, name: "Mayor", events: [event], stats: base_stats()}
      state = %State{room_id: 1, npc: npc, npc_spawner: %{room_id: 1}}

      %{state: state, event: event}
    end

    test "will say to the room", %{state: state, event: event} do
      Events.act_on_tick(state, event)

      [{_, message}] = @room.get_says()
      assert message.message == "Can I help you?"
    end
  end

  describe "quest/completed" do
    setup do
      user = create_user()
      quest = %{id: 1, completed_message: "Hello"}
      npc = %{id: 1, name: "Mayor", events: [], stats: base_stats()}
      state = %State{room_id: 1, npc: npc, npc_spawner: %{room_id: 1}}
      event = {"quest/completed", user, quest}

      Channel.join_tell({:user, user})

      %{state: state, event: event}
    end

    test "sends a tell to the user with the after message", %{state: state, event: event} do
      :ok = Events.act_on(state, event)

      assert_receive {:channel, {:tell, {:npc, _}, %Message{message: "Hello"}}}
    end
  end
end
