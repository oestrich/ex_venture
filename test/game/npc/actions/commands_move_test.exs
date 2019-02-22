defmodule Game.NPC.Actions.CommandsMoveTest do
  use ExVenture.NPCCase

  alias Data.Events.Actions
  alias Game.Door
  alias Game.NPC.State
  alias Game.NPC.Actions.CommandsMove

  doctest CommandsMove

  setup [:basic_setup]

  describe "acting" do
    test "moves to a new room", %{state: state, action: action} do
      {:ok, state} = CommandsMove.act(state, action)

      assert state.room_id == 2

      assert_enter {2, %{type: "npc"}, _}
      assert_leave {1, %{type: "npc"}, _}
    end

    test "does not move if a door is closed", %{state: state, action: action} do
      room_exit = %{id: 10, direction: "north", start_id: 1, finish_id: 2, has_door: true, door_id: 10}

      start_room(%{id: 1, y: 1, exits: [room_exit]})

      Door.load(room_exit)
      Door.set(room_exit, "closed")

      {:ok, state} = CommandsMove.act(state, action)

      assert state.room_id == 1

      refute_enter()
      refute_leave()
    end

    test "does not move when a target is present", %{state: state, action: action} do
      state = %{state | target: {:player, %{}}}

      {:ok, state} = CommandsMove.act(state, action)

      assert state.room_id == 1
    end

    test "does not move if the NPC is unconscious", %{state: state, action: action} do
      stats = %{state.npc.stats | health_points: 0}
      state = %{state | npc: %{state.npc | stats: stats}}

      {:ok, state} = CommandsMove.act(state, action)

      assert state.room_id == 1
    end

    test "does not move if going past the maximum distance", %{state: state, action: action} do
      room_exit = %{direction: "south", start_id: 2, finish_id: 1, has_door: false}
      start_room(%{id: 2, y: 7, exits: [room_exit]})

      {:ok, state} = CommandsMove.act(state, action)

      assert state.room_id == 1

      refute_enter()
      refute_leave()
    end

    test "does not move into a new zone", %{state: state, action: action} do
      start_room(%{id: 2, zone_id: 2})

      {:ok, state} = CommandsMove.act(state, action)

      assert state.room_id == 1

      refute_enter()
      refute_leave()
    end
  end

  def basic_setup(_) do
    npc = npc_attributes(%{id: 1})

    state = %State{
      room_id: 1,
      npc: npc,
      npc_spawner: %{room_id: 1}
    }

    room_exit = %{direction: "north", start_id: 1, finish_id: 2, has_door: false}
    start_room(%{id: 1, y: 1, exits: [room_exit]})

    room_exit = %{direction: "south", start_id: 2, finish_id: 1, has_door: false}
    start_room(%{id: 2, y: 0, exits: [room_exit]})

    start_and_clear_doors()

    action = %Actions.CommandsMove{
      options: %{max_distance: 3}
    }

    %{state: state, action: action}
  end
end
