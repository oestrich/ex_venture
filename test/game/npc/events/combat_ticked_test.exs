defmodule Game.NPC.Events.CombatTickedTest do
  use Data.ModelCase

  alias Data.Events
  alias Game.Character
  alias Game.NPC.Events.CombatTicked
  alias Game.NPC.State

  doctest CombatTicked

  setup [:basic_setup]

  describe "processing the events" do
    test "inserts the target into any commands/target actions", %{state: state} do
      {:ok, ^state} = CombatTicked.process(state)

      assert_receive {:delayed_actions, [action]}
      assert action.options.character == state.target
    end

    test "choses a random event based on weights", %{state: state, event: event} do
      event = %{event | options: %{weight: 0}}

      higher_weighted_event = %Events.CombatTicked{
        options: %{
          weight: 10
        },
        actions: [
          %Events.Actions.CommandsSkill{options: %{skill: "bash"}},
          %Events.Actions.CommandsSkill{options: %{skill: "bash"}},
        ]
      }

      state = %{state | events: [event, higher_weighted_event]}

      {:ok, ^state} = CombatTicked.process(state)

      assert_receive {:delayed_actions, actions}
      assert length(actions) == 2
    end
  end

  def basic_setup(_) do
    event = %Events.CombatTicked{
      options: %{
        weight: 10
      },
      actions: [
        %Events.Actions.CommandsSkill{
          options: %{skill: "bash"}
        }
      ]
    }
    state = %State{
      target: %Character.Simple{type: "player"},
      combat: true,
      events: [event]
    }

    %{state: state, event: event}
  end
end
