defmodule Game.Command.MoveTest do
  use ExVenture.CommandCase

  alias Data.Exit
  alias Data.Proficiency
  alias Game.Command
  alias Game.Command.Move
  alias Game.Door
  alias Game.DoorLock
  alias Game.Session.Registry

  setup do
    start_and_clear_doors()
    start_and_clear_proficiencies()

    user = base_user()
    character = base_character(user)
    state = session_state(%{user: user, character: character, skills: %{}})

    %{user: user, state: state}
  end

  describe "moving in a direction" do
    setup do
      room_exit = %Exit{
        id: 1,
        direction: "north",
        start_id: 1,
        finish_id: 2,
        has_door: false,
        door_id: nil,
        requirements: []
      }

      %{room_exit: room_exit}
    end

    test "north", %{state: state, room_exit: room_exit} do
      start_simple_room(%{exits: [room_exit]})
      start_room(%{id: room_exit.finish_id})

      command = %Command{module: Command.Move, args: {:move, "north"}}

      {:update, state} = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      assert state.save.room_id == 2
    end

    test "north - not found", %{state: state} do
      start_simple_room(%{exits: []})
      command = %Command{module: Command.Move, args: {:move, "north"}}

      {:error, :no_exit} = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))
    end

    test "north - door is closed", %{state: state, room_exit: room_exit} do
      room_exit = %{room_exit | has_door: true, door_id: "uuid"}
      start_simple_room(%{exits: [room_exit]})
      start_room(%{id: room_exit.finish_id})

      Door.load(room_exit)
      Door.set(room_exit, "closed")

      state = Map.merge(state, %{save: %{state.save | room_id: 1}})
      command = %Command{module: Command.Move, args: {:move, "north"}}

      {:update, state} = Command.run(command, state)

      assert state.save.room_id == 2
      assert_socket_echo "opened the door"
    end

    test "north - door is open", %{state: state, room_exit: room_exit} do
      room_exit = %{room_exit | has_door: true, door_id: "uuid"}
      start_simple_room(%{exits: [room_exit]})
      start_room(%{id: room_exit.finish_id})

      Door.load(room_exit)
      Door.set(room_exit, "open")

      state = Map.merge(state, %{save: %{state.save | room_id: 1}})
      command = %Command{module: Command.Move, args: {:move, "north"}}

      {:update, state} = Command.run(command, state)

      assert state.save.room_id == 2
    end

    test "north - requires ranks in a proficiency", %{state: state, room_exit: room_exit} do
      swimming = create_proficiency(%{name: "Swimming"})
      insert_proficiency(swimming)

      requirements = [
        %Proficiency.Requirement{id: swimming.id, ranks: 10}
      ]

      room_exit = %{room_exit | requirements: requirements}
      start_simple_room(%{exits: [room_exit]})

      state = %{state | save: %{state.save | room_id: room_exit.start_id}}
      command = %Command{module: Command.Move, args: {:move, "north"}}

      :ok = Command.run(command, state)

      assert_socket_echo "swimming"
    end
  end

  test "clears the target after moving", %{state: state} do
    room_exit = %Exit{has_door: false, direction: "north", start_id: 1, finish_id: 2, requirements: []}
    start_simple_room(%{exits: [room_exit]})
    start_room(%{id: room_exit.finish_id})
    Registry.register(state.character)

    state = Map.merge(state, %{save: %{room_id: 1}, target: %{type: "player", id: 10}})
    command = %Command{module: Command.Move, args: {:move, "north"}}
    {:update, state} = Command.run(command, state)

    assert state.target == nil
    assert_socket_gmcp {"Target.Clear", "{}"}

    Registry.unregister()
  end

  describe "open a door" do
    setup do
      room_exit = %Exit{id: 10, has_door: true, door_id: 10, direction: "north", start_id: 1, finish_id: 2}
      start_room(%Game.Environment.State.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})

      Door.load(room_exit)
      Door.set(room_exit, "closed")

      %{room_exit: room_exit}
    end

    test "open the door", %{state: state} do
      command = %Command{module: Command.Move, args: {:open, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      assert_socket_echo "opened the door"
      assert_socket_gmcp {"Zone.Map", _}
    end

    test "a door does not exist in the direction", %{state: state} do
      room_exit = %{id: 10, direction: "north", start_id: 1, finish_id: 2, has_door: false}
      start_room(%Game.Environment.State.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:open, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      assert_socket_echo "no door"
    end

    test "an exit does not exist in the direction", %{state: state} do
      start_room(%Game.Environment.State.Room{id: 1, name: "", description: "", exits: [], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:open, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      assert_socket_echo "no exit"
    end

    test "door already open", %{state: state, room_exit: room_exit} do
      Door.set(room_exit, "open")

      command = %Command{module: Command.Move, args: {:open, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      assert_socket_echo "was already open"
    end
  end

  describe "close a door" do
    setup do
      room_exit = %Exit{id: 10, has_door: true, door_id: 10, direction: "north", start_id: 1, finish_id: 2}
      start_room(%Game.Environment.State.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})

      Door.load(room_exit)
      Door.set(room_exit, "open")

      %{room_exit: room_exit}
    end

    test "close the door", %{state: state} do
      command = %Command{module: Command.Move, args: {:close, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      assert_socket_echo "closed the door"
      assert_socket_gmcp {"Zone.Map", _}
    end

    test "a door does not exist in the direction", %{state: state} do
      room_exit = %{id: 10, direction: "north", start_id: 1, finish_id: 2, has_door: false}
      start_room(%Game.Environment.State.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:close, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      assert_socket_echo "no door"
    end

    test "an exit does not exist in the direction", %{state: state} do
      start_room(%Game.Environment.State.Room{id: 1, name: "", description: "", exits: [], players: [], shops: []})

      command = %Command{module: Command.Move, args: {:close, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      assert_socket_echo "no exit"
    end

    test "door already closed", %{state: state, room_exit: room_exit} do
      Door.set(room_exit, "closed")

      command = %Command{module: Command.Move, args: {:close, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      assert_socket_echo "was already closed"
    end
  end

  describe "a locked door" do
    setup do
      start_and_clear_items()
      insert_item(%{id: 1, name: "Key", keywords: []})
      room_exit = %Exit{id: 10, has_door: true, has_lock: true, lock_key_id: 1, door_id: 10, direction: "north", start_id: 1, finish_id: 2}
      start_room(%Game.Environment.State.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})

      Door.load(room_exit)
      Door.set(room_exit, "closed")

      DoorLock.load(room_exit)
      DoorLock.set(room_exit, "locked")

      %{room_exit: room_exit}
    end

    test "locking doesn't do anything", %{state: state, room_exit: room_exit} do
      command = %Command{module: Command.Move, args: {:lock, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      assert_socket_echo "the north door is already locked"
      assert DoorLock.locked?(room_exit)
    end

    test "can't be unlocked without a key", %{state: state, room_exit: room_exit} do
      command = %Command{module: Command.Move, args: {:unlock, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      assert DoorLock.locked?(room_exit)
      assert Door.closed?(room_exit)
      assert_socket_echo "don't have the right key to unlock"
    end

    test "can't be opened if locked and no key", %{state: state, room_exit: room_exit} do
      command = %Command{module: Command.Move, args: {:open, "north"}}
      :ok = Command.run(command, Map.merge(state, %{save: %{room_id: 1}}))

      assert Door.closed?(room_exit)
      assert_socket_echo "door is locked"
    end

    test "can be locked with the key", %{state: state, room_exit: room_exit} do
      state = %{state | save: %{state.save | room_id: 1, items: [item_instance(1)], wielding: %{}}}
      DoorLock.set(room_exit, "unlocked")

      command = %Command{module: Command.Move, args: {:lock, "north"}}
      :ok = Command.run(command, state)

      assert DoorLock.locked?(room_exit)
      assert Door.closed?(room_exit)

      assert_socket_echo "you locked the north door"
    end

    test "can be unlocked with the key", %{state: state, room_exit: room_exit} do
      state = %{state | save: %{state.save | room_id: 1, items: [item_instance(1)], wielding: %{}}}
      command = %Command{module: Command.Move, args: {:unlock, "north"}}
      :ok = Command.run(command, state)

      assert Door.closed?(room_exit)
      refute DoorLock.locked?(room_exit)

      assert_socket_echo "you unlocked the north door"
    end

    test "can be opened with the key", %{state: state, room_exit: room_exit} do
      state = %{state | save: %{state.save | room_id: 1, items: [item_instance(1)], wielding: %{}}}
      command = %Command{module: Command.Move, args: {:open, "north"}}
      :ok = Command.run(command, state)

      refute Door.closed?(room_exit)
      refute DoorLock.locked?(room_exit)

      assert_socket_echo "you unlocked the door"
    end
  end

  describe "cannot leave with a cooldown active" do
    test "you're stuck", %{state: state} do
      room_exit = %Exit{id: 10, direction: "north", start_id: 1, finish_id: 2, has_door: false}
      start_room(%{exits: [room_exit]})

      state = Map.merge(state, %{
        skills: %{10 => Timex.now() |> Timex.shift(seconds: 3)},
        save: %{room_id: 1}
      })

      :ok = Move.run({:move, "north"}, state)

      assert_socket_echo "cannot move"
    end
  end

  describe "maybe_unlock_door" do
    test "can unlock locked door", %{state: state} do
      start_and_clear_items()
      insert_item(%{id: 1, name: "Key", keywords: []})
      room_exit = %Exit{id: 10, has_door: true, has_lock: true, lock_key_id: 1, door_id: 10, direction: "north", start_id: 1, finish_id: 2}
      start_room(%Game.Environment.State.Room{id: 1, name: "", description: "", exits: [room_exit], players: [], shops: []})

      Door.load(room_exit)
      Door.set(room_exit, "closed")

      DoorLock.load(room_exit)
      DoorLock.set(room_exit, "locked")

      state = %{state | save: %{state.save | room_id: 1, items: [item_instance(1)], wielding: %{}}}

      {:ok, _} = Move.maybe_unlock_door(state, room_exit)

      assert DoorLock.unlocked?(room_exit)
    end
  end
end
