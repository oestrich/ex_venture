defmodule Game.Room.ActionsTest do
  use Data.ModelCase

  alias Game.Room

  setup do
    item = create_item(%{name: "Short Sword"})
    village = create_zone(%{name: "Village"})
    room = create_room(village, %{currency: 100, item_ids: [item.id]})
    {:ok, %{room: room, item: item}}
  end

  describe "picking up an item" do
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

  describe "dropping" do
    test "dropping an item", %{room: room, item: item} do
      {:ok, room} = Room.Actions.drop(room, item)

      assert room.item_ids == [item.id, item.id]
    end
  end

  describe "picking up currency" do
    test "picking up currency", %{room: room} do
      {room, {:ok, 100}} = Room.Actions.pick_up_currency(room)

      assert room.currency == 0
    end
  end

  describe "tick - respawning items" do
    setup %{room: room, item: item} do
      create_room_item(room, item, %{spawn: true, spawn_interval: 30})
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
