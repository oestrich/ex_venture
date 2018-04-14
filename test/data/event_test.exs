defmodule Data.EventTest do
  use Data.ModelCase
  doctest Data.Event

  alias Data.Event

  test "loads effects properly for combat ticks" do
    event = %{
      "type" => "combat/tick",
      "action" => %{
        "type" => "target/effects",
        "delay" => 2.1,
        "text" => "A skill was used",
        "effects" => [
          %{"type" => "slashing", "kind" => "damage", "amount" => 10},
        ],
      },
    }

    {:ok, event} = Event.load(event)
    assert event == %{
      type: "combat/tick",
      action: %{
        type: "target/effects",
        delay: 2.1,
        text: "A skill was used",
        effects: [
          %{type: "slashing", kind: "damage", amount: 10},
        ],
      },
    }
  end

  describe "validates the status attribute" do
    test "requires the key" do
      assert Event.valid_status?(%{key: "status"})
      refute Event.valid_status?(%{line: "line text"})
    end

    test "can include line and/or listen and includes a key" do
      assert Event.valid_status?(%{key: "status", listen: "listen text"})
      assert Event.valid_status?(%{key: "status", line: "line text"})
      assert Event.valid_status?(%{key: "status", line: "line text", listen: "listen text"})
    end

    test "keys must be strings" do
      refute Event.valid_status?(%{key: "status", listen: false})
    end

    test "can include reset" do
      assert Event.valid_status?(%{reset: true})
      refute Event.valid_status?(%{reset: false})
    end

    test "cannot include reset with other attributes" do
      refute Event.valid_status?(%{key: "status", line: "line text", listen: "listen text", reset: true})
    end
  end

  describe "validate actions" do
    test "move actions, tick" do
      assert Event.valid_action?("tick", %{type: "move", max_distance: 3, chance: 50, wait: 10})
    end

    test "move actions, tick - must have a wait" do
      refute Event.valid_action?("tick", %{type: "move", max_distance: 3, chance: 150})
    end

    test "say action" do
      assert Event.valid_action?(%{type: "say", message: "hi"})
    end

    test "say action, tick" do
      assert Event.valid_action?("tick", %{type: "say", message: "hi", chance: 50, wait: 20})
      refute Event.valid_action?("tick", %{type: "say", message: "hi"})
    end

    test "say random" do
      assert Event.valid_action?(%{type: "say/random", messages: ["hi"]})
      refute Event.valid_action?(%{type: "say/random", messages: []})
    end

    test "say random, tick" do
      assert Event.valid_action?("tick", %{type: "say/random", messages: ["hi"], chance: 50, wait: 20})
      refute Event.valid_action?("tick", %{type: "say/random", messages: ["hi"]})
    end

    test "emote, tick" do
      assert Event.valid_action?("tick", %{type: "emote", message: "hi", chance: 50, wait: 10})
      refute Event.valid_action?("tick", %{type: "emote", message: "hi"})
    end

    test "emote, tick - changing status" do
      assert Event.valid_action?("tick", %{type: "emote", message: "hi", chance: 50, wait: 10, status: %{reset: true}})
      refute Event.valid_action?("tick", %{type: "emote", message: "hi", chance: 50, wait: 10, status: %{}})
    end

    test "target" do
      assert Event.valid_action?(%{type: "target"})
      refute Event.valid_action?(%{type: "target", extra: "keys"})
    end

    test "target/effects" do
      assert Event.valid_action?(%{type: "target/effects", delay: 1.5, effects: [], weight: 10, text: ""})
      refute Event.valid_action?(%{type: "target/effects", effects: [], weight: 10, text: ""})
    end

    test "target/effects - validates the effects" do
      effect = %{kind: "damage", type: "slashing", amount: 10}
      assert Event.valid_action?(%{type: "target/effects", delay: 1.5, effects: [effect], weight: 10, text: ""})

      refute Event.valid_action?(%{type: "target/effects", delay: 1.5, effects: [%{}], text: ""})
    end

    test "invalid if type is bad" do
      refute Event.valid_action?(%{type: "leave"})
    end
  end
end
