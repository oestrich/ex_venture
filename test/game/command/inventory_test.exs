defmodule Game.Command.InventoryTest do
  use Data.ModelCase

  alias Game.Items

  @socket Test.Networking.Socket

  setup do
    Items.start_link
    Agent.update(Items, fn (_) ->
      %{
        1 => %{name: "Sword"},
        2 => %{name: "Shield"},
        3 => %{name: "Leather Chest"},
      }
    end)

    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket}}
  end

  test "view room information", %{session: session, socket: socket} do
    Game.Command.Inventory.run({}, session, %{socket: socket, save: %{item_ids: [1], wearing: %{chest: 3}, wielding: %{right: 2}}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Sword), look)
  end
end
