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
  end

  describe "validating options" do
    test "empty options" do
      {:ok, %{}} = Events.validate_options(Events.RoomHeard, %{})
    end

    test "verifying type is correct" do
      {:ok, %{regex: "string"}} = Events.validate_options(Events.RoomHeard, %{"regex" => "string"})
    end

    test "extra keys are ignored" do
      {:ok, %{}} = Events.validate_options(Events.RoomHeard, %{"extra" => "string"})
    end

    test "wrong type options returns an error" do
      {:error, %{regex: "invalid"}} = Events.validate_options(Events.RoomHeard, %{"regex" => 10})
    end
  end
end
