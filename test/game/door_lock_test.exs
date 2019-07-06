defmodule Game.DoorLockTest do
  use ExUnit.Case
  import Test.DoorHelper

  alias Game.DoorLock

  setup do
    door_id = 10
    start_and_clear_doors()

    %{door_id: door_id}
  end

  test "load a door's initial state", %{door_id: door_id} do
    "locked" = DoorLock.load(door_id)

    assert DoorLock.get(door_id) == "locked"
    assert DoorLock.locked?(door_id)
    refute DoorLock.unlocked?(door_id)
  end

  test "set the door's state to unlocked", %{door_id: door_id} do
    "locked" = DoorLock.load(door_id)
    assert DoorLock.get(door_id) == "locked"
    assert DoorLock.locked?(door_id)
    refute DoorLock.unlocked?(door_id)

    "unlocked" = DoorLock.set(door_id, "unlocked")
    assert DoorLock.get(door_id) == "unlocked"
    refute DoorLock.locked?(door_id)
    assert DoorLock.unlocked?(door_id)
  end

  test "clear a door", %{door_id: door_id} do
    "locked" = DoorLock.load(door_id)
    assert DoorLock.get(door_id) == "locked"

    DoorLock.remove(%{door_id: door_id})

    assert {:ok, nil} = Cachex.get(:doors, door_id)
  end

  test "clear a door - no cache state for a door loads it", %{door_id: door_id} do
    "locked" = DoorLock.load(door_id)
    assert DoorLock.get(door_id) == "locked"

    DoorLock.remove(%{door_id: door_id})
    assert DoorLock.get(door_id) == "locked"
  end
end
