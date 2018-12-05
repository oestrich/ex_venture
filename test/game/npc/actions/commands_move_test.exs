defmodule Game.NPC.Actions.CommandsMoveTest do
  use Data.ModelCase

  alias Data.Events.Actions
  alias Game.Door
  alias Game.NPC.State
  alias Game.NPC.Actions.CommandsMove

  doctest CommandsMove

  @room Test.Game.Room

  setup [:basic_setup]

  describe "acting" do
    test "moves to a new room", %{state: state, action: action} do
      {:ok, state} = CommandsMove.act(state, action)

      assert state.room_id == 2

      assert [{2, {:npc, _npc}, _reason}] = @room.get_enters()
      assert [{1, {:npc, _npc}, _reason}] = @room.get_leaves()
    end

    test "does not move if a door is closed", %{state: state, action: action} do
      room_exit = %{id: 10, direction: "north", start_id: 1, finish_id: 2, has_door: true, door_id: 10}

      @room._room()
      |> Map.put(:id, 1)
      |> Map.put(:y, 1)
      |> Map.put(:exits, [room_exit])
      |> @room.set_room(multiple: true)

      Door.load(room_exit)
      Door.set(room_exit, "closed")

      {:ok, state} = CommandsMove.act(state, action)

      assert state.room_id == 1

      assert [] = @room.get_enters()
      assert [] = @room.get_leaves()
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
      @room._room()
      |> Map.put(:id, 2)
      |> Map.put(:y, 7)
      |> Map.put(:exits, [%{direction: "south", start_id: 2, finish_id: 1, has_door: false}])
      |> @room.set_room(multiple: true)

      {:ok, state} = CommandsMove.act(state, action)

      assert state.room_id == 1

      assert [] = @room.get_enters()
      assert [] = @room.get_leaves()
    end

    test "does not move into a new zone", %{state: state, action: action} do
      @room._room()
      |> Map.put(:id, 2)
      |> Map.put(:zone_id, 2)
      |> @room.set_room(multiple: true)

      {:ok, state} = CommandsMove.act(state, action)

      assert state.room_id == 1

      assert [] = @room.get_enters()
      assert [] = @room.get_leaves()
    end
  end

  def basic_setup(_) do
    @room.clear_enters()
    @room.clear_leaves()

    npc = npc_attributes(%{id: 1})

    state = %State{
      room_id: 1,
      npc: npc,
      npc_spawner: %{room_id: 1}
    }

    @room._room()
    |> Map.put(:id, 1)
    |> Map.put(:y, 1)
    |> Map.put(:exits, [%{direction: "north", start_id: 1, finish_id: 2, has_door: false}])
    |> @room.set_room(multiple: true)

    @room._room()
    |> Map.put(:id, 2)
    |> Map.put(:y, 0)
    |> Map.put(:exits, [%{direction: "south", start_id: 2, finish_id: 1, has_door: false}])
    |> @room.set_room(multiple: true)

    start_and_clear_doors()

    action = %Actions.CommandsMove{
      options: %{max_distance: 3}
    }

    %{state: state, action: action}
  end
end
