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
end
