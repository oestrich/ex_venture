defmodule Game.Command.PickUpTest do
  use Data.ModelCase

  @socket Test.Networking.Socket
  @room Test.Game.Room

  alias Data.Save

  setup do
    @room.set_room(@room._room())
    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket}}
  end

  test "pick up an item from a room", %{session: session, socket: socket} do
    @room.clear_pick_up()

    {:update, state} = Game.Command.PickUp.run({"sword"}, session, %{socket: socket, save: %Save{room_id: 1, items: []}})

    assert state.save.items |> length == 1

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You picked up), look)
  end

  test "item does not exist in the room", %{session: session, socket: socket} do
    :ok = Game.Command.PickUp.run({"shield"}, session, %{socket: socket, save: %Save{room_id: 1, items: []}})

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

  test "pick up gold from a room", %{session: session, socket: socket} do
    @room.set_pick_up_currency({:ok, 100})

    {:update, state} = Game.Command.PickUp.run({"gold"}, session, %{socket: socket, save: %Save{room_id: 1, currency: 1}})

    assert state.save.currency == 101

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You picked up), look)
  end
end
