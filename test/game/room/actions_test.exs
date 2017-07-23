defmodule Game.Room.ActionsTest do
  use Data.ModelCase

  alias Game.Room

  setup do
    item = create_item(%{name: "Short Sword"})
    room = create_room(%{item_ids: [item.id]})
    {:ok, %{room: room, item: item}}
  end

  test "picking up an item", %{room: room, item: item} do
    {room, {:ok, item}} = Room.Actions.pick_up(room, item)

    assert room.item_ids == []
    assert item.id == item.id
  end

  test "item not found", %{room: room, item: item} do
    item = %{item | id: "bad id"}
    {room, :error} = Room.Actions.pick_up(room, item)

    assert room.item_ids |> length == 1
  end
end
