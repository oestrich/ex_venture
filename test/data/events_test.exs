defmodule Data.EventsTest do
  use ExUnit.Case

  alias Data.Events

  doctest Events

  describe "loading events" do
    test "without actions" do
      {:ok, event} = Events.parse(%{
        "type" => "room/heard",
        "actions" => []
      })

      assert event.__struct__ == Events.RoomHeard
      assert event.actions == []
    end

    test "parsing options" do
      {:ok, event} = Events.parse(%{
        "type" => "room/heard",
        "options" => %{
          "regex" => "hello",
        },
        "actions" => []
      })

      assert event.options == %{regex: "hello"}
    end

    test "with actions" do
      {:ok, event} = Events.parse(%{
        "type" => "room/heard",
        "actions" => [
          %{
            "type" => "channels/say",
            "delay" => 0,
            "options" => %{}
          }
        ]
      })

      assert event.__struct__ == Events.RoomHeard
      assert event.actions == [
        %Events.Actions.ChannelsSay{
          type: "channels/say",
          delay: 0,
          options: %{}
        }
      ]
    end
  end

  describe "action is allowed in the event" do
    test "allowed" do
      assert Events.action_allowed?(Events.RoomHeard, "channels/say")
    end

    test "not allowed" do
      refute Events.action_allowed?(Events.RoomHeard, "combat/target")
    end
  end
end
