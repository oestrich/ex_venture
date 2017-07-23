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

  describe "tick - respawning items" do
    setup %{room: room, item: item} do
      create_room_item(room, item, %{spawn: true, interval: 30})
      room = Repo.preload(room, [:room_items])
      {:ok, %{room: room, item: item}}
    end

    test "does nothing if the item already exists", %{room: room} do
      {:update, %{room: room}} = Room.Actions.tick(%{room: room, respawn: %{}})
      assert room.item_ids |> length == 1
    end

    test "detecting a missing item", %{room: room, item: %{id: item_id}} do
      {:update, state} = Room.Actions.tick(%{room: %{room | item_ids: []}, respawn: %{}})
      assert %{^item_id => _} = state.respawn
    end

    test "doesn't spawn until time", %{room: room, item: %{id: item_id}} do
      {:update, %{room: room}} = Room.Actions.tick(%{room: %{room | item_ids: []}, respawn: %{item_id => Timex.now}})
      assert room.item_ids |> length() == 0
    end

    test "respawns an item", %{room: room, item: %{id: item_id}} do
      time = Timex.now |> Timex.shift(seconds: -31)
      {:update, %{room: room, respawn: respawn}} = Room.Actions.tick(%{room: %{room | item_ids: []}, respawn: %{item_id => time}})
      assert room.item_ids |> length() == 1
      refute respawn |> Map.has_key?(item_id)
    end
  end
end
