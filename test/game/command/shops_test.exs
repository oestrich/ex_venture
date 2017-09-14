defmodule Game.Command.ShopsTest do
  use Data.ModelCase
  doctest Game.Command.Shops

  @socket Test.Networking.Socket
  @room Test.Game.Room
  @shop Test.Game.Shop

  alias Game.Command
  alias Game.Items

  setup do
    Items.start_link
    Agent.update(Items, fn (_) -> %{1 => %{name: "Sword"}} end)

    tree_stand = %{id: 10, name: "Tree Stand Shop", shop_items: [%{item_id: 1, price: 10, quantity: -1}]}
    hole_wall = %{id: 11, name: "Hole in the Wall"}
    room = %{@room._room() | shops: [tree_stand, hole_wall]}

    @room.set_room(room)
    @shop.set_shop(tree_stand)

    @socket.clear_messages
    {:ok, %{session: :session, socket: :socket, room: room}}
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
end
