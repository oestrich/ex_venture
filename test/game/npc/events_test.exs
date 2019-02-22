defmodule Game.NPC.EventsTest do
  use ExVenture.NPCCase

  import Test.DamageTypesHelper

  alias Data.Events.Actions.CommandsSay
  alias Data.Events.RoomHeard
  alias Data.Events.StateTicked
  alias Game.Channel
  alias Game.Character
  alias Game.Events.CharacterDied
  alias Game.Events.QuestCompleted
  alias Game.Events.RoomLeft
  alias Game.Message
  alias Game.NPC.Events
  alias Game.NPC.State

  setup do
    start_and_clear_damage_types()

    %{key: "slashing", stat_modifier: :strength, boost_ratio: 20}
    |> insert_damage_type()

    :ok
  end

  describe "calculating total delay for an event" do
    test "sums up all of the actions" do
      event = %RoomHeard{
        actions: [
          %CommandsSay{delay: 0.5},
          %CommandsSay{delay: 1.5}
        ]
      }

      assert Events.calculate_total_delay(event) == 2000
    end

    test "includes a random delay from the event itself" do
      event = %StateTicked{
        options: %{
          minimum_delay: 2.25,
          random_delay: 2,
        },
        actions: [
          %CommandsSay{delay: 0.5},
          %CommandsSay{delay: 1.5}
        ]
      }

      assert Events.calculate_total_delay(event) > 4250
    end
  end

  describe "character/died" do
    setup do
      npc = %{base_npc() | id: 1, name: "Mayor", events: [], stats: base_stats()}
      user = %{base_user() | id: 2}
      character = %{base_character(user) | id: 2}

      state = %State{room_id: 1, npc: npc, target: nil}

      start_room(%{npcs: [npc], players: [%{id: 1, name: "Player"}]})

      event = %CharacterDied{character: Character.to_simple(character), killer: Character.to_simple(npc)}

      %{state: state, event: event}
    end

    test "clears the target if they were targetting the character", %{state: state, event: event} do
      state = %{state | target: %Character.Simple{type: "player", id: 2}}
      {:update, state} = Events.act_on(state, event)
      assert is_nil(state.target)
    end

    test "does nothing if the target does not match", %{state: state, event: event} do
      :ok = Events.act_on(state, event)
    end
  end

  describe "room/left" do
    test "clears the target when player leaves" do
      npc = %{id: 1, name: "Mayor", events: []}
      state = %State{room_id: 1, npc: npc, target: %Character.Simple{type: "player", id: 2}, combat: true}
      event = %RoomLeft{character: {:player, %{type: "player", id: 2, name: "Player"}}, reason: {:leave, "north"}}

      {:update, state} = Events.act_on(state, event)

      assert is_nil(state.target)
      assert state.combat
    end

    test "does not touch the target if another player leaves" do
      npc = %{id: 1, name: "Mayor", events: []}
      state = %State{room_id: 1, npc: npc, target: %Character.Simple{type: "player", id: 2}}
      event = %RoomLeft{character: {:player, %{type: "player", id: 3, name: "Player"}}, reason: {:leave, "north"}}

      :ok = Events.act_on(state, event)
    end
  end

  describe "quest/completed" do
    setup do
      user = create_user()
      character = Data.Character.from_user(user)
      quest = %{id: 1, completed_message: "Hello"}
      npc = %{base_npc() | id: 1, name: "Mayor", events: [], stats: base_stats()}
      state = %State{room_id: 1, npc: npc, npc_spawner: %{room_id: 1}}
      event = %QuestCompleted{player: character, quest: quest}

      Channel.join_tell(character)

      %{state: state, event: event}
    end

    test "sends a tell to the user with the after message", %{state: state, event: event} do
      :ok = Events.act_on(state, event)

      assert_receive {:channel, {:tell, _, %Message{message: "Hello"}}}
    end
  end
end
