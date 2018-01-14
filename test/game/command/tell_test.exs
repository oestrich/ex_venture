defmodule Game.Command.TellTest do
  use Data.ModelCase
  doctest Game.Command.Tell

  alias Game.Channel
  alias Game.Command.Tell
  alias Game.Message
  alias Game.Session
  alias Game.Session.State

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    @socket.clear_messages
    @room.set_room(Map.merge(@room._room(), %{npcs: []}))
    user = %{id: 10, name: "Player"}
    state = %State{socket: :socket, state: "active", mode: "commands", user: user, save: %{room_id: 1}}
    %{session: :session, state: state}
  end

  describe "send a tell - user" do
    test "send a tell", %{session: session, state: state} do
      Channel.join_tell({:user, state.user})
      Session.Registry.register(state.user)

      {:update, %{reply_to: {:user, _}}} = Tell.run({"tell", "player hello"}, session, state)

      assert_receive {:channel, {:tell, {:user, _}, %Message{message: "hello"}}}
    end

    test "send a tell - player not found", %{session: session, state: state} do
      :ok = Tell.run({"tell", "player hello"}, session, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(not online), echo)
    end
  end

  describe "send a tell - npc" do
    setup %{state: state} do
      npc = create_npc(%{name: "Guard"})

      room = %{id: 1, npcs: [npc]}
      @room.set_room(Map.merge(@room._room(), room))

      %{npc: npc, state: %{state | save: %{room_id: room.id}, reply_to: {:npc, npc}}}
    end

    test "send a tell", %{session: session, state: state, npc: npc} do
      Channel.join_tell({:npc, npc})

      {:update, %{reply_to: {:npc, _}}} = Tell.run({"tell", "guard howdy"}, session, state)

      assert_receive {:channel, {:tell, {:user, _}, %Message{message: "howdy"}}}
    end

    test "send a reply - npc not in the room", %{session: session, state: state} do
      room = %{id: 1, npcs: []}
      @room.set_room(Map.merge(@room._room(), room))

      :ok = Tell.run({"tell", "guard howdy"}, session, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(not), echo)
    end
  end

  describe "send a reply - user" do
    test "send a reply", %{session: session, state: state} do
      Channel.join_tell({:user, state.user})
      Session.Registry.register(state.user)

      :ok = Tell.run({"reply", "howdy"}, session, %{state | reply_to: {:user, state.user}})

      assert_receive {:channel, {:tell, {:user, _}, %Message{message: "howdy"}}}
    end

    test "send a reply - player not online", %{session: session, state: state} do
      :ok = Tell.run({"reply", "howdy"}, session, %{state | reply_to: {:user, state.user}})

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(not online), echo)
    end

    test "send reply - no reply to", %{session: session, state: state} do
      :ok = Tell.run({"reply", "howdy"}, session, %{state | reply_to: nil})

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(no one to reply), echo)
    end
  end

  describe "send a reply - npc" do
    setup %{state: state} do
      npc = create_npc()

      room = %{id: 1, npcs: [npc]}
      @room.set_room(Map.merge(@room._room(), room))

      %{npc: npc, state: %{state | save: %{room_id: room.id}, reply_to: {:npc, npc}}}
    end

    test "send a reply", %{session: session, state: state, npc: npc} do
      Channel.join_tell({:npc, npc})

      :ok = Tell.run({"reply", "howdy"}, session, state)

      assert_receive {:channel, {:tell, {:user, _}, %Message{message: "howdy"}}}
    end

    test "send a reply - npc not in the room", %{session: session, state: state} do
      room = %{id: 1, npcs: []}
      @room.set_room(Map.merge(@room._room(), room))

      :ok = Tell.run({"reply", "howdy"}, session, state)

      [{_, echo}] = @socket.get_echos()
      assert Regex.match?(~r(not), echo)
    end
  end
end
