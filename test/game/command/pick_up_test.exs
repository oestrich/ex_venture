defmodule Game.Command.PickUpTest do
  use ExVenture.CommandCase

  alias Data.Item
  alias Game.Command.PickUp

  doctest PickUp

  setup do
    start_and_clear_items()
    item = create_item(%{name: "Short Sword", description: "A simple blade", keywords: ["sword"]})
    insert_item(item)

    item_instance = Item.instantiate(item)
    room = %{id: 1, items: [item_instance]}
    start_room(room)

    user = base_user()
    character = base_character(user)
    save = %{character.save | room_id: room.id, items: [], currency: 1}
    state = session_state(%{user: user, character: character, save: save})

    %{state: state, room: room, item_instance: item_instance}
  end

  test "pick up an item from a room", %{state: state, room: room, item_instance: item_instance} do
    put_pick_up_response(room, {:ok, item_instance})

    {:update, state} = PickUp.run({"sword"}, state)

    assert state.save.items |> length == 1
    assert_socket_echo "you picked up"
  end

  test "item does not exist in the room", %{state: state} do
    :ok = PickUp.run({"shield"}, state)

    assert_socket_echo ~s("shield" could not be found)
  end

  test "item has already been removed", %{state: state, room: room} do
    put_pick_up_response(room, :error)

    item = %Data.Item{id: 15, name: "shield"}
    room = %Data.Room{id: 1}
    assert {:error, :could_not_pickup, ^item} = PickUp.pick_up(item, room, state)
  end

  test "pick up gold from a room", %{state: state, room: room} do
    put_pick_up_currency_response(room, {:ok, 100})

    {:update, state} = PickUp.run({"gold"}, state)

    assert state.save.currency == 101

    assert_socket_echo "you picked up"
  end

  test "pick up gold from a room, but no gold", %{state: state, room: room} do
    put_pick_up_currency_response(room, {:error, :no_currency})

    :ok = PickUp.run({"gold"}, state)

    assert_socket_echo "no gold"
  end

  describe "pick up all" do
    test "gets everything", %{state: state, room: room, item_instance: item_instance} do
      put_pick_up_response(room, {:ok, item_instance})
      put_pick_up_currency_response(room, {:ok, 100})

      {:update, state} = PickUp.run({:all}, state)

      assert state.save.items |> length() == 1
      assert state.save.currency == 101

      assert_socket_echo "you picked up"
      assert_socket_echo "you picked up"
    end

    test "does not echo currency if not available", %{state: state, room: room, item_instance: item_instance} do
      put_pick_up_response(room, {:ok, item_instance})
      put_pick_up_currency_response(room, {:error, :no_currency})

      {:update, state} = PickUp.run({:all}, state)

      assert state.save.items |> length() == 1
      assert state.save.currency == 1

      assert_socket_echo "you picked up"
    end
  end
end
