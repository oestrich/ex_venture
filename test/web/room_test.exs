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
    # room + event bus
    assert children |> length() == 2

    assert Game.Room._get_state(room.id)
  end

  test "updating a room updates the room state in the supervision tree", %{zone: zone} do
    {:ok, room} = Room.create(zone, room_attributes(%{name: "Forest Path"}))
    {:ok, room} = Room.update(room.id, %{name: "Pathway"})
    assert room.name == "Pathway"

    # Check the supervision tree to make sure casts have gone through
    state = Game.Zone._get_state(zone.id)
    children = state.room_supervisor_pid |> Supervisor.which_children()
    # room + event bus
    assert children |> length() == 2

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
    # room + event bus
    assert children |> length() == 2

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

  describe "exits" do
    test "create an exit", %{zone: zone} do
      {:ok, room1} = Room.create(zone, room_attributes(%{name: "Forest Path"}))
      {:ok, room2} = Room.create(zone, room_attributes(%{name: "Forest Path", y: 2}))

      {:ok, _room_exit} = Room.create_exit(%{"start_room_id" => room1.id, "finish_room_id" => room2.id, "direction" => "south"})

      state = Game.Room._get_state(room1.id)
      assert state.room.exits |> length() == 1

      state = Game.Room._get_state(room2.id)
      assert state.room.exits |> length() == 1
    end

    test "delete a room exit", %{zone: zone} do
      {:ok, room1} = Room.create(zone, room_attributes(%{name: "Forest Path"}))
      {:ok, room2} = Room.create(zone, room_attributes(%{name: "Forest Path", y: 2}))

      {:ok, room_exit} = Room.create_exit(%{"start_room_id" => room1.id, "finish_room_id" => room2.id, "direction" => "south"})
      {:ok, _room_exit} = Room.delete_exit(room_exit.id)

      state = Game.Room._get_state(room1.id)
      assert state.room.exits |> length() == 0

      state = Game.Room._get_state(room2.id)
      assert state.room.exits |> length() == 0
    end

    test "create an exit with proficiency requirements", %{zone: zone} do
      {:ok, room1} = Room.create(zone, room_attributes(%{name: "Forest Path"}))
      {:ok, room2} = Room.create(zone, room_attributes(%{name: "Forest Path", y: 2}))

      {:ok, room_exit} = Room.create_exit(%{
        "start_room_id" => room1.id,
        "finish_room_id" => room2.id,
        "direction" => "south",
        "requirements" => Jason.encode!([
          %{"id" => 1, "ranks" => 5}
        ])
      })

      assert Enum.count(room_exit.requirements) == 1

      [requirement] = room_exit.requirements
      assert requirement.id == 1
      assert requirement.ranks == 5
    end
  end

  describe "room features" do
    test "add a new room feature", %{zone: zone} do
      {:ok, room} = Room.create(zone, room_attributes(%{}))

      {:ok, _feature} = Room.add_feature(room, %{"key" => "log", "short_description" => "short", "description" => "Long"})

      state = Game.Room._get_state(room.id)
      assert state.room.features |> length() == 1
    end

    test "edit a room feature", %{zone: zone} do
      {:ok, room} = Room.create(zone, room_attributes(%{}))

      {:ok, _feature} = Room.add_feature(room, %{"key" => "log", "short_description" => "short", "description" => "Long"})

      state = Game.Room._get_state(room.id)
      [feature] = state.room.features

      {:ok, _room} = Room.edit_feature(room, feature.id, %{"key" => "log", "short_description" => "short", "description" => "longer"})

      state = Game.Room._get_state(room.id)
      assert [%{description: "longer"}] = state.room.features
    end

    test "remove a room feature", %{zone: zone} do
      {:ok, room} = Room.create(zone, room_attributes(%{}))

      {:ok, feature} = Room.add_feature(room, %{"key" => "log", "short_description" => "short", "description" => "Long"})
      {:ok, _feature} = Room.delete_feature(room, feature.id)

      state = Game.Room._get_state(room.id)
      assert state.room.features |> length() == 0
    end
  end

  describe "global features" do
    test "add a feature", %{zone: zone} do
      {:ok, room} = Room.create(zone, room_attributes(%{}))
      {:ok, feature} = create_feature()

      {:ok, _feature} = Room.add_global_feature(room, Integer.to_string(feature.id))

      state = Game.Room._get_state(room.id)
      assert state.room.feature_ids |> length() == 1
    end

    test "remove a feature", %{zone: zone} do
      {:ok, room} = Room.create(zone, room_attributes(%{}))
      {:ok, feature} = create_feature()

      {:ok, _room} = Room.add_global_feature(room, Integer.to_string(feature.id))
      {:ok, _room} = Room.remove_global_feature(room, Integer.to_string(feature.id))

      state = Game.Room._get_state(room.id)
      assert state.room.features |> length() == 0
    end
  end

  describe "deleting a room" do
    setup %{zone: zone} do
      params = %{
        name: "Forest Path",
        description: "A small forest path",
        currency: "10",
        x: 1,
        y: 1,
        map_layer: 1,
      }

      {:ok, room} = Room.create(zone, params)

      %{room: room}
    end

    test "does not delete a zone graveyard - is_graveyard", %{room: room} do
      {:ok, room} = Room.update(room.id, %{is_graveyard: true})
      assert {:error, :graveyard, _room} = Room.delete(room.id)
    end

    test "does not delete a zone graveyard - is_graveyard: false, but still attached", %{zone: zone, room: room} do
      {:ok, _zone} = Zone.update(zone.id, %{graveyard_id: room.id})

      assert {:error, :graveyard, _room} = Room.delete(room.id)
    end

    test "does not delete the starting room", %{room: room} do
      create_config(:starting_save, %{room_id: room.id} |> Poison.encode!())

      assert {:error, :starting_room, _room} = Room.delete(room.id)
    end
  end
end
