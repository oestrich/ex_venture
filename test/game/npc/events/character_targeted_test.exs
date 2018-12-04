defmodule Game.NPC.Events.CharacterTargetedTest do
  use Data.ModelCase

  alias Data.Events
  alias Game.NPC.Events.CharacterTargeted
  alias Game.NPC.State

  doctest CharacterTargeted

  setup [:basic_setup]

  describe "processing the events" do
    test "inserts the character into any commands/target actions", %{state: state} do
      player = {:player, %{}}
      sent_event = {"character/targeted", {:from, player}}

      {:ok, ^state} = CharacterTargeted.process(state, sent_event)

      assert_receive {:delayed_actions, [action]}
      assert action.options.character == player
    end
  end

  def basic_setup(_) do
    event = %Events.CharacterTargeted{
      actions: [
        %Events.Actions.CommandsTarget{}
      ]
    }
    state = %State{events: [event]}

    %{state: state}
  end
end
