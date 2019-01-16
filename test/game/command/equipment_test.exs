defmodule Game.Command.EquipmentTest do
  use ExVenture.CommandCase

  alias Game.Command.Equipment

  doctest Equipment

  setup do
    start_and_clear_items()
    insert_item(%{id: 1, name: "Sword"})
    insert_item(%{id: 2, name: "Shield"})
    insert_item(%{id: 3, name: "Leather Chest"})

    {:ok, %{socket: :socket}}
  end

  test "view your equipment", %{socket: socket} do
    state = %{socket: socket, save: %{item_ids: [1], wearing: %{chest: 3}, wielding: %{right: 2}}}
    Equipment.run({}, state)

    assert_socket_echo ["shield", "leather"]
  end
end
