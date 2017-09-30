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
    @socket.clear_messages()
    {:ok, %{session: :session, socket: :socket, room: room}}
  end

  describe "parsing" do
    test "bad parse of buy" do
      command = Command.Shops.parse("shops buy sword tree top")
      assert command == {:error, :bad_parse, "shops buy sword tree top"}
    end

    test "bad parse of show" do
      command = Command.Shops.parse("shops show sword tree top")
      assert command == {:error, :bad_parse, "shops show sword tree top"}
    end
  end

  test "view shops in the room", %{session: session, socket: socket} do
    Command.Shops.run({}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(Tree Stand Shop), look)
    assert Regex.match?(~r(Hole in the Wall), look)
  end

  test "view items in a shop", %{session: session, socket: socket} do
    Command.Shops.run({:list, "tree stand"}, session, %{socket: socket, save: %{room_id: 1}})

    [{^socket, list}] = @socket.get_echos()
    assert Regex.match?(~r(Tree Stand Shop), list)
    assert Regex.match?(~r(Sword), list)
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
end
