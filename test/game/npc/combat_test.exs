defmodule Game.NPC.CombatTest do
  use ExUnit.Case
  doctest Game.NPC.Combat

  alias Game.NPC.Combat

  describe "weighted combat/ticks" do
    setup do
      weight_ten = %{type: "combat/tick", action: %{type: "target/effects", delay: 1.5, effects: [], weight: 10, text: ""}}
      weight_three = %{type: "combat/tick", action: %{type: "target/effects", delay: 1.5, effects: [], weight: 3, text: ""}}

      %{weight_ten: weight_ten, weight_three: weight_three, events: [weight_ten, weight_three]}
    end

    test "handles an empty list" do
      assert is_nil(Combat.weighted_event([]))
    end

    test "gets total size", %{events: events} do
      assert Combat.total_weights(events) == 13
    end

    test "determine the 'winner' based on the random number", %{weight_ten: weight_ten, weight_three: weight_three} do
      events = [weight_ten, weight_three]

      assert Combat.select_action(9, events) == weight_ten
      assert Combat.select_action(11, events) == weight_three
    end
  end
end
