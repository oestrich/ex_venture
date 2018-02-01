defmodule Web.RoomTest do
  use Data.ModelCase

  alias Web.Room
  alias Web.Zone

  setup do
    {:ok, zone} = Zone.create(zone_attributes(%{name: "The Forest"}))
    %{zone: zone}
  end

  test "creating a new room adds a child to the room supervision tree", %{zone: zone} do
    params = %{
      name: "Forest Path",
      description: "A small forest path",
      currency: "10",
      x: 1,
      y: 1,
      map_layer: 1,
    }

    {:ok, room} = Room.create(zone, params)
    assert room.name == "Forest Path"

    state = Game.Zone._get_state(zone.id)
    children = state.room_supervisor_pid |> Supervisor.which_children()
    assert children |> length() == 1

    assert Game.Room._get_state(room.id)
  end

  test "updating a room updates the room state in the supervision tree", %{zone: zone} do
    {:ok, room} = Room.create(zone, room_attributes(%{name: "Forest Path"}))
    {:ok, room} = Room.update(room.id, %{name: "Pathway"})
    assert room.name == "Pathway"

    # Check the supervision tree to make sure casts have gone through
    state = Game.Zone._get_state(zone.id)
    children = state.room_supervisor_pid |> Supervisor.which_children()
    assert children |> length() == 1

    state = Game.Room._get_state(room.id)
    assert state.room.name == "Pathway"
  end

  test "adding an item to a room", %{zone: zone} do
    {:ok, room} = Room.create(zone, room_attributes(%{name: "Forest Path"}))
    item = create_item()

    start_and_clear_items()
    insert_item(item)

    # Check the supervision tree to make sure casts have gone through
    state = Game.Zone._get_state(zone.id)
    children = state.room_supervisor_pid |> Supervisor.which_children()
    assert children |> length() == 1

    {:ok, room} = Room.add_item(room, item.id)

    state = Game.Room._get_state(room.id)
    assert state.room.items |> length() == 1
  end

  test "create a room item", %{zone: zone} do
    {:ok, room} = Room.create(zone, room_attributes(%{name: "Forest Path"}))
    item = create_item()
    {:ok, room} = Room.update(room.id, %{name: "Pathway"})

    {:ok, _room_item} = Room.create_item(room, %{item_id: item.id, spawn_interval: 15})

    state = Game.Room._get_state(room.id)
    assert state.room.room_items |> length() == 1
  end

  test "delete room item", %{zone: zone} do
    {:ok, room} = Room.create(zone, room_attributes(%{name: "Forest Path"}))
    item = create_item()
    room_item = create_room_item(room, item, %{spawn_interval: 15})
    {:ok, room} = Room.update(room.id, %{name: "Pathway"})

    {:ok, _room_item} = Room.delete_item(room_item.id)

    state = Game.Room._get_state(room.id)
    assert state.room.room_items |> length() == 0
  end

  test "create an exit", %{zone: zone} do
    {:ok, room1} = Room.create(zone, room_attributes(%{name: "Forest Path"}))
    {:ok, room2} = Room.create(zone, room_attributes(%{name: "Forest Path", y: 2}))

    {:ok, _room_exit} = Room.create_exit(%{north_id: room1.id, south_id: room2.id})

    state = Game.Room._get_state(room1.id)
    assert state.room.exits |> length() == 1

    state = Game.Room._get_state(room2.id)
    assert state.room.exits |> length() == 1
  end

  test "delete a room exit", %{zone: zone} do
    {:ok, room1} = Room.create(zone, room_attributes(%{name: "Forest Path"}))
    {:ok, room2} = Room.create(zone, room_attributes(%{name: "Forest Path", y: 2}))

    {:ok, room_exit} = Room.create_exit(%{north_id: room1.id, south_id: room2.id})
    {:ok, _room_exit} = Room.delete_exit(room_exit.id)

    state = Game.Room._get_state(room1.id)
    assert state.room.exits |> length() == 0

    state = Game.Room._get_state(room2.id)
    assert state.room.exits |> length() == 0
  end
end
