defmodule Game.NPC.EventsTest do
  use Data.ModelCase

  @room Test.Game.Room

  alias Game.Message
  alias Game.NPC.Events

  setup do
    @room.clear_says()
  end

  describe "room/entered" do
    test "say something to the room when a player enters it" do
      npc_spawner = %{room_id: 1}
      npc = %{name: "Mayor", events: [%{type: "room/entered", action: "say", arguments: ["Hello"]}]}

      :ok = Events.act_on(%{npc_spawner: npc_spawner, npc: npc}, {:enter, {:user, :session, %{}}})

      [{_, message}] = @room.get_says()
      assert message.message == "Hello"
    end

    test "do nothing when an NPC enters the room" do
      npc_spawner = %{room_id: 1}
      npc = %{name: "Mayor", events: [%{type: "room/entered", action: "say", arguments: ["Hello"]}]}

      :ok = Events.act_on(%{npc_spawner: npc_spawner, npc: npc}, {:enter, {:npc, %{}}})

      assert @room.get_says() |> length() == 0
    end
  end

  describe "room/heard" do
    test "matches condition" do
      npc_spawner = %{room_id: 1}
      npc = %{name: "Mayor", events: [%{type: "room/heard", condition: "hi", action: "say", arguments: ["Hello"]}]}

      :ok = Events.act_on(%{npc_spawner: npc_spawner, npc: npc}, {:heard, Message.new(%{name: "name"}, "Hi")})

      [{_, message}] = @room.get_says()
      assert message.message == "Hello"
    end

    test "does not match condition" do
      npc_spawner = %{room_id: 1}
      npc = %{name: "Mayor", events: [%{type: "room/heard", condition: "hi", action: "say", arguments: ["Hello"]}]}

      :ok = Events.act_on(%{npc_spawner: npc_spawner, npc: npc}, {:heard, Message.new(%{name: "name"}, "Howdy")})

      assert [] = @room.get_says()
    end

    test "no condition" do
      npc_spawner = %{room_id: 1}
      npc = %{name: "Mayor", events: [%{type: "room/heard", condition: nil, action: "say", arguments: ["Hello"]}]}

      :ok = Events.act_on(%{npc_spawner: npc_spawner, npc: npc}, {:heard, Message.new(%{name: "name"}, "Howdy")})

      [{_, message}] = @room.get_says()
      assert message.message == "Hello"
    end
  end
end
