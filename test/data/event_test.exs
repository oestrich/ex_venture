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
    assert event.id
    assert Map.take(event, [:type, :action]) == %{
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

  describe "valid?" do
    test "validate combat/tick" do
      assert Event.valid?(%{
        id: "id",
        type: "combat/tick",
        action: %{type: "target/effects", effects: [], delay: 1.5, weight: 10, text: ""},
      })

      refute Event.valid?(%{
        id: "id",
        type: "combat/tick",
        action: %{type: "target/effects", effects: :invalid},
      })
    end

    test "validate room/entered" do
      assert Event.valid?(%{
        id: "id",
        type: "room/entered",
        action: %{type: "say", message: "hi"},
      })

      refute Event.valid?(%{
        id: "id",
        type: "room/entered",
        action: %{type: "say", message: :invalid},
      })
    end

    test "validate room/heard" do
      assert Event.valid?(%{
        id: "id",
        type: "room/heard",
        condition: %{regex: "hello"},
        action: %{type: "say", message: "hi"},
      })

      refute Event.valid?(%{
        id: "id",
        type: "room/heard",
        condition: nil,
        action: %{type: "say", message: "hi"},
      })

      refute Event.valid?(%{
        id: "id",
        type: "room/heard",
        condition: %{regex: "hello"},
        action: %{type: "say", message: nil},
      })
    end

    test "validate tick" do
      assert Event.valid?(%{
        id: "id",
        type: "tick",
        action: %{type: "move", max_distance: 3, chance: 50, wait: 10},
      })

      refute Event.valid?(%{
        id: "id",
        type: "tick",
        action: %{type: "move"},
      })
    end
  end

  describe "valid actions for types" do
    test "combat tickets" do
      assert Event.valid_action_for_type?(%{type: "combat/tick", action: %{type: "target/effects"}})
      refute Event.valid_action_for_type?(%{type: "combat/tick", action: %{type: "say"}})
    end

    test "room entered" do
      assert Event.valid_action_for_type?(%{type: "room/entered", action: %{type: "say"}})
      assert Event.valid_action_for_type?(%{type: "room/entered", action: %{type: "say/random"}})
      assert Event.valid_action_for_type?(%{type: "room/entered", action: %{type: "target"}})
      refute Event.valid_action_for_type?(%{type: "room/entered", action: %{type: "move"}})
    end

    test "room heard" do
      assert Event.valid_action_for_type?(%{type: "room/heard", action: %{type: "say"}})
      refute Event.valid_action_for_type?(%{type: "room/heard", action: %{type: "move"}})
    end

    test "tick" do
      assert Event.valid_action_for_type?(%{type: "tick", action: %{type: "move"}})
      assert Event.valid_action_for_type?(%{type: "tick", action: %{type: "emote"}})
      assert Event.valid_action_for_type?(%{type: "tick", action: %{type: "say"}})
      assert Event.valid_action_for_type?(%{type: "tick", action: %{type: "say/random"}})
      refute Event.valid_action_for_type?(%{type: "tick", action: %{type: "target/effects"}})
    end
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
      assert Event.validate_tick_action(%{type: "move", max_distance: 3, chance: 50, wait: 10}).valid?
    end

    test "move actions, tick - must have a wait" do
      refute Event.validate_tick_action(%{type: "move", max_distance: 3, chance: 150}).valid?
    end

    test "say action" do
      assert Event.validate_action(%{type: "say", message: "hi"}).valid?
    end

    test "say action, tick" do
      assert Event.validate_tick_action(%{type: "say", message: "hi", chance: 50, wait: 20}).valid?
      refute Event.validate_tick_action(%{type: "say", message: "hi"}).valid?
    end

    test "say random" do
      assert Event.validate_action(%{type: "say/random", messages: ["hi"]}).valid?
      refute Event.validate_action(%{type: "say/random", messages: []}).valid?
    end

    test "say random, tick" do
      assert Event.validate_tick_action(%{type: "say/random", messages: ["hi"], chance: 50, wait: 20}).valid?
      refute Event.validate_tick_action(%{type: "say/random", messages: ["hi"]}).valid?
    end

    test "emote, tick" do
      assert Event.validate_tick_action(%{type: "emote", message: "hi", chance: 50, wait: 10}).valid?
      refute Event.validate_tick_action(%{type: "emote", message: "hi"}).valid?
    end

    test "emote, tick - changing status" do
      assert Event.validate_tick_action(%{type: "emote", message: "hi", chance: 50, wait: 10, status: %{reset: true}}).valid?
      refute Event.validate_tick_action(%{type: "emote", message: "hi", chance: 50, wait: 10, status: %{}}).valid?
    end

    test "target" do
      assert Event.validate_action(%{type: "target"}).valid?
      refute Event.validate_action(%{type: "target", extra: "keys"}).valid?
    end

    test "target/effects" do
      assert Event.validate_action(%{type: "target/effects", delay: 1.5, effects: [], weight: 10, text: ""}).valid?
      refute Event.validate_action(%{type: "target/effects", effects: [], weight: 10, text: ""}).valid?
    end

    test "target/effects - validates the effects" do
      effect = %{kind: "damage", type: "slashing", amount: 10}
      assert Event.validate_action(%{type: "target/effects", delay: 1.5, effects: [effect], weight: 10, text: ""}).valid?

      refute Event.validate_action(%{type: "target/effects", delay: 1.5, effects: [%{}], text: ""}).valid?
    end

    test "invalid if type is bad" do
      refute Event.validate_action(%{type: "leave"}).valid?
    end
  end

  describe "valdiation conditions" do
    test "room heard - regex" do
      assert Event.valid_condition?(%{type: "room/heard", condition: %{regex: "hello"}})
      refute Event.valid_condition?(%{type: "room/heard", condition: %{regex: :hello}})
    end

    test "any other type" do
      assert Event.valid_condition?(%{type: "combat/tick"})
      refute Event.valid_condition?(%{type: "combat/tick", condition: %{regex: "hello"}})
    end
  end
end
