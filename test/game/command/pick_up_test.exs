defmodule Game.Command.PickUpTest do
  use Data.ModelCase

  @socket Test.Networking.Socket
  @room Test.Game.Room

  alias Data.Item
  alias Data.Save

  setup do
    start_and_clear_items()
    item = create_item(%{name: "Short Sword", description: "A simple blade", keywords: ["sword"]})
    insert_item(item)
    @room.set_room(Map.merge(@room._room(), %{items: [Item.instantiate(item)]}))
    @socket.clear_messages
    {:ok, %{socket: :socket}}
  end

  test "pick up an item from a room", %{socket: socket} do
    @room.clear_pick_up()

    {:update, state} = Game.Command.PickUp.run({"sword"}, %{socket: socket, save: %Save{room_id: 1, items: []}})

    assert state.save.items |> length == 1

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You picked up), look)
  end

  test "item does not exist in the room", %{socket: socket} do
    :ok = Game.Command.PickUp.run({"shield"}, %{socket: socket, save: %Save{room_id: 1, items: []}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r("shield" could not be found), look)
  end

  test "item has already been removed", %{socket: socket} do
    @room.set_pick_up(:error)

    item = %Data.Item{id: 15, name: "shield"}
    room = %Data.Room{id: 1}
    :ok = Game.Command.PickUp.pick_up(item, room, %{socket: socket, save: %Save{room_id: 1, items: []}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r("shield" could not be found), look)
  end

  test "pick up gold from a room", %{socket: socket} do
    @room.set_pick_up_currency({:ok, 100})

    {:update, state} = Game.Command.PickUp.run({"gold"}, %{socket: socket, save: %Save{room_id: 1, currency: 1}})

    assert state.save.currency == 101

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You picked up), look)
  end
end
