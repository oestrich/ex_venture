defmodule Game.DoorTest do
  use ExUnit.Case
  import Test.DoorHelper

  alias Game.Door

  setup do
    exit_id = 10
    start_and_clear_doors()

    %{exit_id: exit_id}
  end

  test "load a door's initial state", %{exit_id: exit_id} do
    "closed" = Door.load(exit_id)

    assert Door.get(exit_id) == "closed"
    assert Door.closed?(exit_id)
    refute Door.open?(exit_id)
  end

  test "set the door's state to open", %{exit_id: exit_id} do
    "closed" = Door.load(exit_id)
    assert Door.get(exit_id) == "closed"
    assert Door.closed?(exit_id)
    refute Door.open?(exit_id)

    "open" = Door.set(exit_id, "open")
    assert Door.get(exit_id) == "open"
    refute Door.closed?(exit_id)
    assert Door.open?(exit_id)
  end

  test "clear a door", %{exit_id: exit_id} do
    "closed" = Door.load(exit_id)
    assert Door.get(exit_id) == "closed"

    :ok = Door.remove(%{id: exit_id})
    assert is_nil(Door.get(exit_id))
  end
end
