defmodule Game.NPC.Events.RoomEnteredTest do
  use Data.ModelCase

  alias Data.Events
  alias Game.Character
  alias Game.Events.RoomEntered, as: GameRoomEntered
  alias Game.NPC.Events.RoomEntered
  alias Game.NPC.State

  doctest RoomEntered

  setup [:basic_setup]

  describe "processing the events" do
    test "with no options", %{state: state} do
      sent_event = %GameRoomEntered{character: {:player, %{}}}

      {:ok, ^state} = RoomEntered.process(state, sent_event)

      assert_receive {:delayed_actions, [_]}
    end

    test "inserts the character into any commands/target actions", %{state: state, event: event} do
      player = %Character.Simple{}
      sent_event = %GameRoomEntered{character: player}

      event = %{event | actions: [%Events.Actions.CommandsTarget{}]}
      state = %{state | events: [event]}

      {:ok, ^state} = RoomEntered.process(state, sent_event)

      assert_receive {:delayed_actions, [action]}
      assert action.options.character == player
    end
  end

  def basic_setup(_) do
    event = %Events.RoomEntered{
      actions: [
        %Events.Actions.CommandsSay{}
      ]
    }
    state = %State{events: [event]}

    %{state: state, event: event}
  end
end
