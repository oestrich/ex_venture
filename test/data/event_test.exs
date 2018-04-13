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
end
