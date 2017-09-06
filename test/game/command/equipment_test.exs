defmodule Game.Command.EquipmentTest do
  use Data.ModelCase

  alias Game.Items
  alias Game.Command.Equipment

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

  test "view your equipment", %{session: session, socket: socket} do
    state = %{socket: socket, save: %{item_ids: [1], wearing: %{chest: 3}, wielding: %{right: 2}}}
    Equipment.run({}, session, state)

    [{^socket, look}] = @socket.get_echos()
    refute Regex.match?(~r(Sword), look)
    assert Regex.match?(~r(Shield), look)
    assert Regex.match?(~r(Leather), look)
  end
end
