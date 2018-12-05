defmodule Game.NPC.Events.StateTickedTest do
  use Data.ModelCase

  alias Data.Events
  alias Game.NPC.Events.StateTicked
  alias Game.NPC.State

  doctest StateTicked

  setup [:basic_setup]

  describe "processing the events" do
    test "runs the event that ticked", %{state: state, event: event} do
      {:ok, ^state} = StateTicked.process(state, event)

      assert_receive {:delayed_actions, [action]}
    end
  end

  def basic_setup(_) do
    event = %Events.StateTicked{
      actions: [
        %Events.Actions.CommandsSay{}
      ]
    }
    state = %State{events: [event]}

    %{state: state, event: event}
  end
end
