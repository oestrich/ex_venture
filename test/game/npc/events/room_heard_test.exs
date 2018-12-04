defmodule Game.NPC.Events.RoomHeardTest do
  use Data.ModelCase

  alias Data.Events
  alias Game.Message
  alias Game.NPC.Events.RoomHeard
  alias Game.NPC.State

  doctest RoomHeard

  setup [:basic_setup]

  describe "processing the events" do
    test "with no options", %{state: state} do
      sent_event = {"room/heard", %Message{message: "hello"}}

      {:ok, ^state} = RoomHeard.process(state, sent_event)

      assert_receive {:delayed_actions, [_]}
    end

    test "with a regex that matches", %{state: state, event: event} do
      event = %{event | options: %{regex: "hello"}}
      state = %{state | events: [event]}
      sent_event = {"room/heard", %Message{message: "hello"}}

      {:ok, ^state} = RoomHeard.process(state, sent_event)

      assert_receive {:delayed_actions, [_]}
    end

    test "with a regex that does not match", %{state: state, event: event} do
      event = %{event | options: %{regex: "hi"}}
      state = %{state | events: [event]}
      sent_event = {"room/heard", %Message{message: "hello"}}

      {:ok, ^state} = RoomHeard.process(state, sent_event)

      refute_receive {:delayed_actions, [_]}
    end
  end

  def basic_setup(_) do
    event = %Events.RoomHeard{
      actions: [
        %Events.Actions.CommandsSay{}
      ]
    }
    state = %State{events: [event]}

    %{state: state, event: event}
  end
end
