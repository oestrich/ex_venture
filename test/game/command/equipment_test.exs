defmodule Game.Command.EquipmentTest do
  use Data.ModelCase

  alias Game.Command.Equipment

  @socket Test.Networking.Socket

  setup do
    start_and_clear_items()
    insert_item(%{id: 1, name: "Sword"})
    insert_item(%{id: 2, name: "Shield"})
    insert_item(%{id: 3, name: "Leather Chest"})

    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket}}
  end

  test "view your equipment", %{session: session, socket: socket} do
    state = %{socket: socket, save: %{item_ids: [1], wearing: %{chest: 3}, wielding: %{right: 2}}}
    Equipment.run({}, session, state)

    [{^socket, look}] = @socket.get_echos()
    refute Regex.match?(~r(Sword), look)
    assert Regex.match?(~r(Shield), look)
    assert Regex.match?(~r(Leather), look)
  end
end
