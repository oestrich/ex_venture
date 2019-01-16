defmodule Game.Command.InventoryTest do
  use ExVenture.CommandCase

  alias Game.Command.Inventory

  doctest Inventory

  setup do
    start_and_clear_items()
    insert_item(%{id: 1, name: "Sword"})
    insert_item(%{id: 2, name: "Shield"})
    insert_item(%{id: 3, name: "Leather Chest"})

    {:ok, %{socket: :socket}}
  end

  test "view your inventory", %{socket: socket} do
    state = %{socket: socket, save: %{currency: 10, items: [item_instance(1)], wearing: %{chest: item_instance(3)}, wielding: %{right: item_instance(2)}}}
    {:paginate, inv, _} = Inventory.run({}, state)

    assert Regex.match?(~r(Sword), inv)
    assert Regex.match?(~r(Shield), inv)
    assert Regex.match?(~r(Leather), inv)
    assert Regex.match?(~r(10 gold), inv)
  end
end
