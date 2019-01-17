defmodule Game.Command.ShopsTest do
  use ExVenture.CommandCase

  alias Game.Command.Shops
  alias Game.Environment.State.Overworld

  doctest Game.Command.Shops

  setup do
    start_and_clear_items()
    insert_item(%{id: 1, name: "Sword", keywords: [], description: ""})

    tree_stand = %{id: 10, name: "Tree Stand Shop", shop_items: [%{item_id: 1, price: 10, quantity: -1}]}
    hole_wall = %{id: 11, name: "Hole in the Wall"}
    start_shop(tree_stand)

    start_room(%{shops: [tree_stand, hole_wall]})

    %{state: session_state(%{}), tree_stand: tree_stand}
  end

  test "a bad shop command displays help", %{state: state} do
    :ok = Shops.run({:help}, state)

    assert_socket_echo "see {command}help shops{/command}"
  end

  test "view shops in the room", %{state: state} do
    :ok = Shops.run({}, %{state | save: %{room_id: 1}})

    assert_socket_echo ["tree stand shop", "hole in the wall"]
  end

  test "view shops in the room - overworld", %{state: state} do
    start_room(%Overworld{id: "overworld:1:1,1"})

    :ok = Shops.run({}, %{state | save: %{room_id: "overworld:1:1,1"}})

    assert_socket_echo "no shops"
  end

  test "view shops in the room - no shops", %{state: state} do
    start_room(%{shops: []})

    :ok = Shops.run({}, %{state | save: %{room_id: 1}})

    assert_socket_echo "no shops"
  end

  test "view items in a shop", %{state: state} do
    :ok = Shops.run({:list, "tree stand"}, %{state | save: %{room_id: 1}})

    assert_socket_echo ["tree stand shop", "sword"]
  end

  test "view items in a shop - one shop", %{state: state, tree_stand: tree_stand} do
    start_room(%{shops: [tree_stand]})

    :ok = Shops.run({:list}, %{state | save: %{room_id: 1}})

    assert_socket_echo ["tree stand shop", "sword"]
  end

  test "view items in a shop - one shop - more than one shop", %{state: state} do
    :ok = Shops.run({:list}, %{state | save: %{room_id: 1}})

    assert_socket_echo "more than one shop"
  end

  test "view items in a shop - one shop - no shop found", %{state: state} do
    start_room(%{shops: []})

    :ok = Shops.run({:list}, %{state | save: %{room_id: 1}})

    assert_socket_echo "could not"
  end

  test "view items in a shop - bad shop name", %{state: state} do
    :ok = Shops.run({:list, "stand"}, %{state | save: %{room_id: 1}})

    assert_socket_echo "could not be found"
  end

  test "view an item in a shop", %{state: state} do
    :ok = Shops.run({:show, "sword", :from, "tree stand"}, %{state | save: %{room_id: 1}})

    assert_socket_echo "sword"
  end

  test "view an item in a shop - item not found", %{state: state} do
    :ok = Shops.run({:show, "shield", :from, "tree stand"}, %{state | save: %{room_id: 1}})

    assert_socket_echo "could not"
  end

  test "view an item in a shop - one shop", %{state: state, tree_stand: tree_stand} do
    start_room(%{shops: [tree_stand]})

    :ok = Shops.run({:show, "sword"}, %{state | save: %{room_id: 1}})

    assert_socket_echo "sword"
  end

  test "view an item in a shop - one shop - more than one shop", %{state: state} do
    :ok = Shops.run({:show, "sword"}, %{state | save: %{room_id: 1}})

    assert_socket_echo "more than one shop"
  end

  test "view an item in a shop - one shop - no shop found", %{state: state} do
    start_room(%{shops: []})

    :ok = Shops.run({:show, "sword"}, %{state | save: %{room_id: 1}})

    assert_socket_echo "could not"
  end

  test "view an item in a shop - shop not found", %{state: state} do
    :ok = Shops.run({:show, "sword", :from, "tre3"}, %{state | save: %{room_id: 1}})

    assert_socket_echo "could not"
  end

  test "buy an item in a shop", %{state: state, tree_stand: tree_stand} do
    save = %{base_save() | room_id: 1, currency: 20}
    put_shop_buy_response(tree_stand, {:ok, %{save | currency: 19}, %{name: "Sword"}})

    {:update, state} = Shops.run({:buy, "sword", :from, "tree stand"}, %{state | save: save})

    assert state.save.currency == 19
    assert_shop_buy {_, "sword", _}
    assert_socket_echo ["tree stand shop", "sword"]
  end

  test "buy an item in a shop - shop not found", %{state: state} do
    save = %{base_save() | room_id: 1, currency: 20}
    :ok = Shops.run({:buy, "sword", :from, "treestand"}, %{state | save: save})

    assert_socket_echo "could not"
  end

  test "buy an item in a shop - one shop", %{state: state, tree_stand: tree_stand} do
    start_room(%{shops: [tree_stand]})

    save = %{base_save() | room_id: 1, currency: 20}
    put_shop_buy_response(tree_stand, {:ok, %{save | currency: 19}, %{name: "Sword"}})

    {:update, state} = Shops.run({:buy, "sword"}, %{state | save: save})

    assert state.save.currency == 19
    assert_shop_buy {_, "sword", _}
    assert_socket_echo ["tree stand", "sword"]
  end

  test "buy an item in a shop - one shop - but more than one shop in room", %{state: state} do
    save = %{base_save() | room_id: 1, currency: 20}
    :ok = Shops.run({:buy, "sword"}, %{state | save: save})

    assert_socket_echo "more than one"
  end

  test "buy an item in a shop - one shop parse - no shop in room", %{state: state} do
    start_room(%{shops: []})

    save = %{base_save() | room_id: 1, currency: 20}
    :ok = Shops.run({:buy, "sword"}, %{state | save: save})

    assert_socket_echo "could not"
  end

  test "buy an item in a shop - item not found", %{state: state, tree_stand: tree_stand} do
    put_shop_buy_response(tree_stand, {:error, :item_not_found})

    save = %{base_save() | room_id: 1, currency: 20}
    :ok = Shops.run({:buy, "swrd", :from, "tree stand"}, %{state | save: save})

    assert_shop_buy {_, "swrd", _}
    assert_socket_echo "item could not"
  end

  test "buy an item in a shop - not enough currency", %{state: state, tree_stand: tree_stand} do
    put_shop_buy_response(tree_stand, {:error, :not_enough_currency, %{name: "Sword"}})

    save = %{base_save() | room_id: 1, currency: 20}
    :ok = Shops.run({:buy, "sword", :from, "tree stand"}, %{state | save: save})

    assert_shop_buy {_, "sword", _}
    assert_socket_echo "do not have"
  end

  test "buy an item in a shop - not enough quantity", %{state: state, tree_stand: tree_stand} do
    put_shop_buy_response(tree_stand, {:error, :not_enough_quantity, %{name: "Sword"}})

    save = %{base_save() | room_id: 1, currency: 20}
    :ok = Shops.run({:buy, "sword", :from, "tree stand"}, %{state | save: save})

    assert_shop_buy {_, "sword", _}
    assert_socket_echo "does not"
  end

  test "sell an item to a shop", %{state: state, tree_stand: tree_stand} do
    save = %{base_save() | room_id: 1, currency: 20, items: [item_instance(1)]}
    put_shop_sell_response(tree_stand, {:ok, %{save | currency: 30}, %{name: "Sword", cost: 10}})

    {:update, state} = Shops.run({:sell, "sword", :to, "tree stand"}, %{state | save: save})

    assert state.save.currency == 30

    assert_shop_sell {_, "sword", _}
    assert_socket_echo "10 gold"
  end

  test "sell an item to a shop - one shop", %{state: state, tree_stand: tree_stand} do
    start_room(%{shops: [tree_stand]})

    save = %{base_save() | room_id: 1, currency: 20, items: [item_instance(1)]}
    put_shop_sell_response(tree_stand, {:ok, %{save | currency: 30}, %{name: "Sword", cost: 10}})

    {:update, state} = Shops.run({:sell, "sword"}, %{state | save: save})

    assert state.save.currency == 30

    assert_shop_sell {_, "sword", _}
    assert_socket_echo "10 gold"
  end

  test "sell an item in a shop - one shop - but more than one shop in room", %{state: state} do
    save = %{base_save() | room_id: 1, currency: 20}
    :ok = Shops.run({:sell, "sword"}, %{state | save: save})

    assert_socket_echo "more than one"
  end

  test "sell an item in a shop - one shop parse - no shop in room", %{state: state} do
    start_room(%{shops: []})

    save = %{base_save() | room_id: 1, currency: 20}
    :ok = Shops.run({:sell, "sword"}, %{state | save: save})

    assert_socket_echo "could not"
  end

  test "sell an item to a shop - shop not found", %{state: state} do
    save = %{base_save() | room_id: 1, currency: 20, items: [item_instance(1)]}
    :ok = Shops.run({:sell, "sword", :to, "treestand"}, %{state | save: save})

    assert_socket_echo "could not"
  end

  test "sell an item to a shop - item not found", %{state: state, tree_stand: tree_stand} do
    put_shop_sell_response(tree_stand, {:error, :item_not_found})

    save = %{base_save() | room_id: 1, currency: 20, items: [item_instance(1)]}
    :ok = Shops.run({:sell, "swrd", :to, "tree stand"}, %{state | save: save})

    assert_shop_sell {_, "swrd", _}
    assert_socket_echo "could not"
  end
end
