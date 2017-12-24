defmodule Game.Command.ShopsTest do
  use Data.ModelCase
  doctest Game.Command.Shops

  @socket Test.Networking.Socket
  @room Test.Game.Room
  @shop Test.Game.Shop

  alias Game.Command

  setup do
    start_and_clear_items()
    insert_item(%{id: 1, name: "Sword", keywords: [], description: ""})

    tree_stand = %{id: 10, name: "Tree Stand Shop", shop_items: [%{item_id: 1, price: 10, quantity: -1}]}
    hole_wall = %{id: 11, name: "Hole in the Wall"}
    room = %{@room._room() | shops: [tree_stand, hole_wall]}

    @room.set_room(room)
    @shop.set_shop(tree_stand)

    @shop.clear_buys()
    @shop.clear_sells()
    @socket.clear_messages()
    {:ok, %{session: :session, socket: :socket, room: room, tree_stand: tree_stand}}
  end

  test "a bad shop command displays help", %{session: session, socket: socket} do
    Command.Shops.run({:help}, session, %{socket: socket})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(see {white}help shops{/white}), look)
  end

  test "view shops in the room", %{session: session, socket: socket} do
    Command.Shops.run({}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Tree Stand Shop), look)
    assert Regex.match?(~r(Hole in the Wall), look)
  end

  test "view shops in the room - no shops", %{session: session, socket: socket} do
    room = %{@room._room() | shops: []}
    @room.set_room(room)

    Command.Shops.run({}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(no shops), look)
  end

  test "view items in a shop", %{session: session, socket: socket} do
    Command.Shops.run({:list, "tree stand"}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(Tree Stand Shop), list)
    assert Regex.match?(~r(Sword), list)
  end

  test "view items in a shop - one shop", %{session: session, socket: socket, room: room, tree_stand: tree_stand} do
    room = %{room | shops: [tree_stand]}
    @room.set_room(room)

    Command.Shops.run({:list}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(Tree Stand Shop), list)
    assert Regex.match?(~r(Sword), list)
  end

  test "view items in a shop - one shop - more than one shop", %{session: session, socket: socket} do
    Command.Shops.run({:list}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(more than one shop), list)
  end

  test "view items in a shop - one shop - no shop found", %{session: session, socket: socket, room: room} do
    room = %{room | shops: []}
    @room.set_room(room)

    Command.Shops.run({:list}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(could not), list)
  end

  test "view items in a shop - bad shop name", %{session: session, socket: socket} do
    Command.Shops.run({:list, "stand"}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r("stand" shop could not be found), list)
  end

  test "view an item in a shop", %{session: session, socket: socket} do
    Command.Shops.run({:show, "sword", :from, "tree stand"}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(Sword), list)
  end

  test "view an item in a shop - item not found", %{session: session, socket: socket} do
    Command.Shops.run({:show, "shield", :from, "tree stand"}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(could not), list)
  end

  test "view an item in a shop - one shop", %{session: session, socket: socket, room: room, tree_stand: tree_stand} do
    room = %{room | shops: [tree_stand]}
    @room.set_room(room)

    Command.Shops.run({:show, "sword"}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(Sword), list)
  end

  test "view an item in a shop - one shop - more than one shop", %{session: session, socket: socket} do
    Command.Shops.run({:show, "sword"}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(more than one shop), list)
  end

  test "view an item in a shop - one shop - no shop found", %{session: session, socket: socket, room: room} do
    room = %{room | shops: []}
    @room.set_room(room)

    Command.Shops.run({:show, "sword"}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(could not), list)
  end

  test "view an item in a shop - shop not found", %{session: session, socket: socket} do
    :ok = Command.Shops.run({:show, "sword", :from, "tre3"}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(could not), list)
  end

  test "buy an item in a shop", %{session: session, socket: socket} do
    save = %{base_save() | room_id: 1, currency: 20}
    @shop.set_buy({:ok, %{save | currency: 19}, %{name: "Sword"}})

    {:update, state} = Command.Shops.run({:buy, "sword", :from, "tree stand"}, session, %{socket: socket, save: save})

    assert state.save.currency == 19
    assert [{_, "sword", _save}] = @shop.get_buys()

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(Tree Stand Shop), list)
    assert Regex.match?(~r(Sword), list)
  end

  test "buy an item in a shop - shop not found", %{session: session, socket: socket} do
    save = %{base_save() | room_id: 1, currency: 20}
    :ok = Command.Shops.run({:buy, "sword", :from, "treestand"}, session, %{socket: socket, save: save})

    assert [] = @shop.get_buys()

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r("treestand" shop could not), list)
  end

  test "buy an item in a shop - one shop", %{session: session, socket: socket, room: room, tree_stand: tree_stand} do
    room = %{room | shops: [tree_stand]}
    @room.set_room(room)

    save = %{base_save() | room_id: 1, currency: 20}
    @shop.set_buy({:ok, %{save | currency: 19}, %{name: "Sword"}})

    {:update, state} = Command.Shops.run({:buy, "sword"}, session, %{socket: socket, save: save})

    assert state.save.currency == 19
    assert [{_, "sword", _save}] = @shop.get_buys()

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(Tree Stand Shop), list)
    assert Regex.match?(~r(Sword), list)
  end

  test "buy an item in a shop - one shop - but more than one shop in room", %{session: session, socket: socket} do
    save = %{base_save() | room_id: 1, currency: 20}
    :ok = Command.Shops.run({:buy, "sword"}, session, %{socket: socket, save: save})

    assert [] = @shop.get_buys()

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(more than one shop), list)
  end

  test "buy an item in a shop - one shop parse - no shop in room", %{session: session, socket: socket, room: room} do
    room = %{room | shops: []}
    @room.set_room(room)

    save = %{base_save() | room_id: 1, currency: 20}
    :ok = Command.Shops.run({:buy, "sword"}, session, %{socket: socket, save: save})

    assert [] = @shop.get_buys()

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(shop could not), list)
  end

  test "buy an item in a shop - item not found", %{session: session, socket: socket} do
    @shop.set_buy({:error, :item_not_found})

    save = %{base_save() | room_id: 1, currency: 20}
    :ok = Command.Shops.run({:buy, "swrd", :from, "tree stand"}, session, %{socket: socket, save: save})

    assert [{_, "swrd", _}] = @shop.get_buys()

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r("swrd" item could not), list)
  end

  test "buy an item in a shop - not enough currency", %{session: session, socket: socket} do
    @shop.set_buy({:error, :not_enough_currency, %{name: "Sword"}})

    save = %{base_save() | room_id: 1, currency: 20}
    :ok = Command.Shops.run({:buy, "sword", :from, "tree stand"}, session, %{socket: socket, save: save})

    assert [{_id, "sword", _save}] = @shop.get_buys()

    [{^socket, buy}] = @socket.get_echos()
    assert Regex.match?(~r(You do not have), buy)
  end

  test "buy an item in a shop - not enough quantity", %{session: session, socket: socket} do
    @shop.set_buy({:error, :not_enough_quantity, %{name: "Sword"}})

    save = %{base_save() | room_id: 1, currency: 20}
    :ok = Command.Shops.run({:buy, "sword", :from, "tree stand"}, session, %{socket: socket, save: save})

    assert [{_id, "sword", _save}] = @shop.get_buys()

    [{^socket, buy}] = @socket.get_echos()
    assert Regex.match?(~r("Tree Stand Shop" does not ), buy)
  end

  test "sell an item to a shop", %{session: session, socket: socket} do
    save = %{base_save() | room_id: 1, currency: 20, items: [item_instance(1)]}
    @shop.set_sell({:ok, %{save | currency: 30}, %{name: "Sword", cost: 10}})

    {:update, state} = Command.Shops.run({:sell, "sword", :to, "tree stand"}, session, %{socket: socket, save: save})

    assert state.save.currency == 30
    assert [{_, "sword", _save}] = @shop.get_sells()

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(Tree Stand Shop), list)
    assert Regex.match?(~r(Sword), list)
    assert Regex.match?(~r(10 gold), list)
  end

  test "sell an item to a shop - one shop", %{session: session, socket: socket, room: room, tree_stand: tree_stand} do
    room = %{room | shops: [tree_stand]}
    @room.set_room(room)

    save = %{base_save() | room_id: 1, currency: 20, items: [item_instance(1)]}
    @shop.set_sell({:ok, %{save | currency: 30}, %{name: "Sword", cost: 10}})

    {:update, state} = Command.Shops.run({:sell, "sword"}, session, %{socket: socket, save: save})

    assert state.save.currency == 30
    assert [{_, "sword", _save}] = @shop.get_sells()

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(Tree Stand Shop), list)
    assert Regex.match?(~r(Sword), list)
    assert Regex.match?(~r(10 gold), list)
  end

  test "sell an item in a shop - one shop - but more than one shop in room", %{session: session, socket: socket} do
    save = %{base_save() | room_id: 1, currency: 20}
    :ok = Command.Shops.run({:sell, "sword"}, session, %{socket: socket, save: save})

    assert [] = @shop.get_sells()

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(more than one shop), list)
  end

  test "sell an item in a shop - one shop parse - no shop in room", %{session: session, socket: socket, room: room} do
    room = %{room | shops: []}
    @room.set_room(room)

    save = %{base_save() | room_id: 1, currency: 20}
    :ok = Command.Shops.run({:sell, "sword"}, session, %{socket: socket, save: save})

    assert [] = @shop.get_sells()

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(shop could not), list)
  end

  test "sell an item to a shop - shop not found", %{session: session, socket: socket} do
    save = %{base_save() | room_id: 1, currency: 20, items: [item_instance(1)]}
    :ok = Command.Shops.run({:sell, "sword", :to, "treestand"}, session, %{socket: socket, save: save})

    assert [] = @shop.get_sells()

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r("treestand" shop could not), list)
  end

  test "sell an item to a shop - item not found", %{session: session, socket: socket} do
    @shop.set_sell({:error, :item_not_found})

    save = %{base_save() | room_id: 1, currency: 20, items: [item_instance(1)]}
    :ok = Command.Shops.run({:sell, "swrd", :to, "tree stand"}, session, %{socket: socket, save: save})

    assert [{_, "swrd", _}] = @shop.get_sells()

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r("swrd" item could not), list)
  end
end
