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
    state = %{socket: socket, save: %{currency: 10, item_ids: [1], wearing: %{chest: 3}, wielding: %{right: 2}}}
    Game.Command.Inventory.run({}, session, state)

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Sword), look)
    assert Regex.match?(~r(Shield), look)
    assert Regex.match?(~r(Leather), look)
    assert Regex.match?(~r(10 gold), look)
  end
end
