defmodule Game.Command.DropTest do
  use ExVenture.CommandCase

  alias Game.Command.Drop

  setup do
    start_and_clear_items()
    insert_item(%{id: 1, name: "Sword", keywords: []})

    user = base_user()
    state = session_state(%{user: user})

    %{state: state}
  end

  test "drop an item in a room", %{state: state} do
    state = %{state | save: %{state.save | room_id: 1, items: [item_instance(1)]}}

    {:update, state} = Drop.run({"sword"}, state)

    assert state.save.items |> length == 0

    assert_socket_echo "you dropped"
    assert_drop {_, {:player, _}, %{id: 1}}
  end

  test "drop currency in a room", %{state: state} do
    state = %{state | save: %{state.save | room_id: 1, currency: 101}}
    {:update, state} = Drop.run({"100 gold"}, state)

    assert state.save.currency == 1

    assert_socket_echo "you dropped"
    assert_drop {_, {:player, _}, {:currency, 100}}
  end

  test "drop currency in a room - not enough to do so", %{state: state} do
    state = %{state | save: %{state.save | room_id: 1, currency: 101}}

    :ok = Drop.run({"110 gold"}, state)

    assert_socket_echo "you do not have enough"
  end

  test "item not found in your inventory", %{state: state} do
    state = %{state | save: %{state.save | room_id: 1, items: [item_instance(2)]}}
    :ok = Drop.run({"sword"}, state)

    assert_socket_echo "could not find"
  end
end
