defmodule Game.Command.InventoryTest do
  use Data.ModelCase

  @socket Test.Networking.Socket

  setup do
    start_and_clear_items()
    insert_item(%{id: 1, name: "Sword"})
    insert_item(%{id: 2, name: "Shield"})
    insert_item(%{id: 3, name: "Leather Chest"})

    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket}}
  end

  test "view your inventory", %{session: session, socket: socket} do
    state = %{socket: socket, save: %{currency: 10, items: [item_instance(1)], wearing: %{chest: item_instance(3)}, wielding: %{right: item_instance(2)}}}
    {:paginate, inv, _} = Game.Command.Inventory.run({}, session, state)

    assert Regex.match?(~r(Sword), inv)
    assert Regex.match?(~r(Shield), inv)
    assert Regex.match?(~r(Leather), inv)
    assert Regex.match?(~r(10 gold), inv)
  end
end
