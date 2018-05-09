defmodule Game.Command.PickUpTest do
  use Data.ModelCase
  doctest Game.Command.PickUp

  @socket Test.Networking.Socket
  @room Test.Game.Room

  alias Data.Item
  alias Data.Save
  alias Game.Command.PickUp
  alias Game.Session.State

  setup do
    start_and_clear_items()
    item = create_item(%{name: "Short Sword", description: "A simple blade", keywords: ["sword"]})
    insert_item(item)

    @room.set_room(Map.merge(@room._room(), %{items: [Item.instantiate(item)]}))
    @socket.clear_messages()

    state = %State{
      socket: :socket,
      state: "active",
      mode: "commands",
      save: %Save{
        room_id: 1,
        items: [],
        currency: 1,
      }
    }

    {:ok, %{state: state}}
  end

  test "pick up an item from a room", %{state: state} do
    @room.clear_pick_up()

    {:update, state} = PickUp.run({"sword"}, state)

    assert state.save.items |> length == 1

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You picked up), look)
  end

  test "item does not exist in the room", %{state: state} do
    :ok = PickUp.run({"shield"}, state)

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r("shield" could not be found), look)
  end

  test "item has already been removed", %{state: state} do
    @room.set_pick_up(:error)

    item = %Data.Item{id: 15, name: "shield"}
    room = %Data.Room{id: 1}
    assert {:error, :could_not_pickup, ^item} = PickUp.pick_up(item, room, state)
  end

  test "pick up gold from a room", %{state: state} do
    @room.set_pick_up_currency({:ok, 100})

    {:update, state} = PickUp.run({"gold"}, state)

    assert state.save.currency == 101

    [{_socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(You picked up), look)
  end

  test "pick up all from a room", %{state: state} do
    @room.set_pick_up_currency({:ok, 100})

    {:update, state} = PickUp.run({:all}, state)

    assert state.save.items |> length() == 1
    assert state.save.currency == 101

    [{_socket1, item}, {_socket2, currency}] = @socket.get_echos()
    assert Regex.match?(~r(You picked up), item)
    assert Regex.match?(~r(You picked up), currency)
  end
end
