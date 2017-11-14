defmodule Game.NPC.EventsTest do
  use Data.ModelCase

  @room Test.Game.Room

  alias Game.Message
  alias Game.NPC.Events
  alias Game.Session.Registry

  setup do
    @room.clear_says()
  end

  describe "room/entered" do
    test "say something to the room when a player enters it" do
      npc_spawner = %{room_id: 1}
      npc = %{name: "Mayor", events: [%{type: "room/entered", action: %{type: "say", message: "Hello"}}]}

      :ok = Events.act_on(%{npc_spawner: npc_spawner, npc: npc}, {"room/entered", {:user, :session, %{}}})

      [{_, message}] = @room.get_says()
      assert message.message == "Hello"
    end

    test "do nothing when an NPC enters the room" do
      npc_spawner = %{room_id: 1}
      npc = %{name: "Mayor", events: [%{type: "room/entered", action: %{type: "say", message: "Hello"}}]}

      :ok = Events.act_on(%{npc_spawner: npc_spawner, npc: npc}, {"room/entered", {:npc, %{}}})

      assert @room.get_says() |> length() == 0
    end

    test "target the player when they entered" do
      Registry.register(%{id: 2})

      npc_spawner = %{room_id: 1}
      npc = %{id: 1, name: "Mayor", events: [%{type: "room/entered", action: %{type: "target"}}]}

      :ok = Events.act_on(%{npc_spawner: npc_spawner, npc: npc}, {"room/entered", {:user, :session, %{id: 2}}})

      assert_received {:"$gen_cast", {:targeted, {:npc, %{id: 1}}}}
    end
  end

  describe "room/heard" do
    test "matches condition" do
      npc_spawner = %{room_id: 1}
      npc = %{name: "Mayor", events: [%{type: "room/heard", condition: %{regex: "hi"}, action: %{type: "say", message: "Hello"}}]}

      :ok = Events.act_on(%{npc_spawner: npc_spawner, npc: npc}, {"room/heard", Message.new(%{name: "name"}, "Hi")})

      [{_, message}] = @room.get_says()
      assert message.message == "Hello"
    end

    test "does not match condition" do
      npc_spawner = %{room_id: 1}
      npc = %{name: "Mayor", events: [%{type: "room/heard", condition: %{regex: "hi"}, action: %{type: "say", message: "Hello"}}]}

      :ok = Events.act_on(%{npc_spawner: npc_spawner, npc: npc}, {"room/heard", Message.new(%{name: "name"}, "Howdy")})

      assert [] = @room.get_says()
    end

    test "no condition" do
      npc_spawner = %{room_id: 1}
      npc = %{name: "Mayor", events: [%{type: "room/heard", condition: nil, action: %{type: "say", message: "Hello"}}]}

      :ok = Events.act_on(%{npc_spawner: npc_spawner, npc: npc}, {"room/heard", Message.new(%{name: "name"}, "Howdy")})

      [{_, message}] = @room.get_says()
      assert message.message == "Hello"
    end
  end
end
