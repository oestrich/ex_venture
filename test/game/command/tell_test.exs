defmodule Game.Command.TellTest do
  use ExVenture.CommandCase

  alias Game.Channel
  alias Game.Command.Tell
  alias Game.Message
  alias Game.Session

  doctest Tell

  setup do
    user = base_user()
    character = base_character(user)
    save = %{character.save | room_id: 1}

    %{state: session_state(%{user: user, character: character, save: save})}
  end

  describe "send a tell - user" do
    test "send a tell", %{state: state} do
      Channel.join_tell(state.character)
      Session.Registry.register(state.character)
      Session.Registry.catch_up()

      {:update, %{reply_to: %{type: "player"}}} = Tell.run({"tell", "player hello"}, state)

      assert_receive {:channel, {:tell, _, %Message{message: "Hello."}}}
    end

    test "send a tell - player not found", %{state: state} do
      start_room(%{})

      :ok = Tell.run({"tell", "player hello"}, state)

      assert_socket_echo "not online"
    end
  end

  describe "send a tell - npc" do
    setup %{state: state} do
      npc = create_npc(%{name: "Guard"})

      room = %{id: 1, npcs: [npc]}
      start_room(room)

      %{npc: npc, state: %{state | save: %{room_id: room.id}, reply_to: npc}}
    end

    test "send a tell", %{state: state, npc: npc} do
      Channel.join_tell(npc)

      {:update, %{reply_to: %{type: "npc"}}} = Tell.run({"tell", "guard howdy"}, state)

      assert_receive {:channel, {:tell, _, %Message{message: "Howdy."}}}
    end

    test "send a tell - npc not in the room", %{state: state} do
      start_room(%{npcs: []})

      :ok = Tell.run({"tell", "guard howdy"}, state)

      assert_socket_echo "not"
    end
  end

  describe "send a reply - user" do
    test "send a reply", %{state: state} do
      Channel.join_tell(state.character)
      Session.Registry.register(state.character)
      Session.Registry.catch_up()

      :ok = Tell.run({"reply", "howdy"}, %{state | reply_to: state.character})

      assert_receive {:channel, {:tell, _, %Message{message: "Howdy."}}}
    end

    test "send a reply - player not online", %{state: state} do
      :ok = Tell.run({"reply", "howdy"}, %{state | reply_to: state.character})

      assert_socket_echo "not online"
    end

    test "send reply - no reply to", %{state: state} do
      :ok = Tell.run({"reply", "howdy"}, %{state | reply_to: nil})

      assert_socket_echo "no one to reply"
    end
  end

  describe "send a reply - npc" do
    setup %{state: state} do
      npc = create_npc()

      room = %{id: 1, npcs: [npc]}
      start_room(room)

      %{npc: npc, state: %{state | save: %{room_id: room.id}, reply_to: npc}}
    end

    test "send a reply", %{state: state, npc: npc} do
      Channel.join_tell(npc)

      :ok = Tell.run({"reply", "howdy"}, state)

      assert_receive {:channel, {:tell, _, %Message{message: "Howdy."}}}
    end

    test "send a reply - npc not in the room", %{state: state} do
      start_room(%{id: 1, npcs: []})

      :ok = Tell.run({"reply", "howdy"}, state)

      assert_socket_echo "not"
    end
  end
end
