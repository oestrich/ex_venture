defmodule Game.DoorTest do
  use ExUnit.Case
  import Test.DoorHelper

  alias Game.Door

  setup do
    door_id = 10
    start_and_clear_doors()

    %{door_id: door_id}
  end

  test "load a door's initial state", %{door_id: door_id} do
    "closed" = Door.load(door_id)

    assert Door.get(door_id) == "closed"
    assert Door.closed?(door_id)
    refute Door.open?(door_id)
  end

  test "set the door's state to open", %{door_id: door_id} do
    "closed" = Door.load(door_id)
    assert Door.get(door_id) == "closed"
    assert Door.closed?(door_id)
    refute Door.open?(door_id)

    "open" = Door.set(door_id, "open")
    assert Door.get(door_id) == "open"
    refute Door.closed?(door_id)
    assert Door.open?(door_id)
  end

  test "clear a door", %{door_id: door_id} do
    "closed" = Door.load(door_id)
    assert Door.get(door_id) == "closed"

    Door.remove(%{door_id: door_id})

    assert {:ok, nil} = Cachex.get(:doors, door_id)
  end

  test "clear a door - no cache state for a door loads it", %{door_id: door_id} do
    "closed" = Door.load(door_id)
    assert Door.get(door_id) == "closed"

    Door.remove(%{door_id: door_id})
    assert Door.get(door_id) == "closed"
  end
end
