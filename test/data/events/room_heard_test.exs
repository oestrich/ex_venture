defmodule Data.Events.RoomHeardTest do
  use ExUnit.Case

  alias Data.Events
  alias Data.Events.RoomHeard

  describe "parsing a room/heard event" do
    test "without actions" do
      {:ok, event} = Events.parse(%{
        "type" => "room/heard",
        "actions" => []
      })

      assert event.__struct__ == RoomHeard
      assert event.actions == []
    end
  end

  describe "allowed actions" do
    test "say" do
      assert Enum.member?(RoomHeard.allowed_actions(), "commands/say")
    end

    test "emote" do
      assert Enum.member?(RoomHeard.allowed_actions(), "commands/emote")
    end
  end
end
