defmodule Game.Command.DropTest do
  use Data.ModelCase

  @socket Test.Networking.Socket
  @room Test.Game.Room

  alias Game.Command.Drop

  setup do
    start_and_clear_items()
    insert_item(%{id: 1, name: "Sword", keywords: []})

    @socket.clear_messages()

    user = base_user()
    state = session_state(%{user: user})

    %{state: state}
  end

  test "drop an item in a room", %{state: state} do
    @room.clear_drops()

    state = %{state | save: %{state.save | room_id: 1, items: [item_instance(1)]}}

    {:update, state} = Drop.run({"sword"}, state)

    assert state.save.items |> length == 0

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You dropped), look)

    assert [{1, {:player, _}, %{id: 1}}] = @room.get_drops()
  end

  test "drop currency in a room", %{state: state} do
    @room.clear_drop_currencies()

    state = %{state | save: %{state.save | room_id: 1, currency: 101}}
    {:update, state} = Drop.run({"100 gold"}, state)

    assert state.save.currency == 1

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You dropped), look)

    assert [{1, {:player, _}, 100}] = @room.get_drop_currencies()
  end

  test "drop currency in a room - not enough to do so", %{state: state} do
    @room.clear_drop_currencies()

    state = %{state | save: %{state.save | room_id: 1, currency: 101}}
    :ok = Drop.run({"110 gold"}, state)

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You do not have enough), look)
  end

  test "item not found in your inventory", %{state: state} do
    state = %{state | save: %{state.save | room_id: 1, items: [item_instance(2)]}}
    :ok = Drop.run({"sword"}, state)

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Could not find), look)
  end
end
