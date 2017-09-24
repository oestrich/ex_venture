defmodule Game.Command.DropTest do
  use Data.ModelCase

  @socket Test.Networking.Socket
  @room Test.Game.Room

  alias Data.Save

  setup do
    start_and_clear_items()
    insert_item(%{id: 1, name: "Sword", keywords: []})

    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket}}
  end

  test "drop an item in a room", %{session: session, socket: socket} do
    @room.clear_drops()

    state = %{socket: socket, user: %{name: "user"}, save: %Save{room_id: 1, item_ids: [1]}}
    {:update, state} = Game.Command.Drop.run({"sword"}, session, state)

    assert state.save.item_ids |> length == 0

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You dropped), look)

    assert [{1, {:user, _}, %{id: 1}}] = @room.get_drops()
  end

  test "drop currency in a room", %{session: session, socket: socket} do
    @room.clear_drop_currencies()

    state = %{socket: socket, user: %{name: "user"}, save: %Save{room_id: 1, currency: 101}}
    {:update, state} = Game.Command.Drop.run({"100 gold"}, session, state)

    assert state.save.currency == 1

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You dropped), look)

    assert [{1, {:user, _}, 100}] = @room.get_drop_currencies()
  end

  test "drop currency in a room - not enough to do so", %{session: session, socket: socket} do
    @room.clear_drop_currencies()

    state = %{socket: socket, user: %{name: "user"}, save: %Save{room_id: 1, currency: 101}}
    :ok = Game.Command.Drop.run({"110 gold"}, session, state)

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You do not have enough), look)
  end

  test "item not found in your inventory", %{session: session, socket: socket} do
    :ok = Game.Command.Drop.run({"sword"}, session, %{socket: socket, save: %Save{room_id: 1, item_ids: [2]}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Could not find), look)
  end
end
