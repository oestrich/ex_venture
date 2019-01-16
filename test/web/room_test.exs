defmodule Web.RoomTest do
  use Data.ModelCase

  alias Web.Room
  alias Web.Zone

  setup do
    zone = create_zone(%{name: "The Forest"})

    %{zone: zone}
  end

  test "creating a new room adds a child to the room supervision tree", %{zone: zone} do
    NamedProcess.start_link({Game.Zone, zone.id})

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

    assert_receive {{Game.Zone, _}, {:cast, {:spawn_room, _}}}
  end

  test "updating a room updates the room state in the supervision tree", %{zone: zone} do
    room = create_room(zone, %{name: "Forest Path"})
    NamedProcess.start_link({Game.Room, room.id})

    {:ok, room} = Room.update(room.id, %{name: "Pathway"})

    assert room.name == "Pathway"
    assert_receive {_, {:cast, {:update, _}}}
  end

  test "adding an item to a room", %{zone: zone} do
    room = create_room(zone, %{name: "Forest Path"})
    NamedProcess.start_link({Game.Room, room.id})

    item = create_item()
    start_and_clear_items()
    insert_item(item)

    {:ok, room} = Room.add_item(room, item.id)

    assert length(room.items) == 1
    assert_receive {_, {:cast, {:update, _}}}
  end

  test "create a room item", %{zone: zone} do
    room = create_room(zone, %{name: "Forest Path"})
    NamedProcess.start_link({Game.Room, room.id})

    item = create_item()

    {:ok, _room_item} = Room.create_item(room, %{item_id: item.id, spawn_interval: 15})

    assert_receive {_, {:cast, {:update, _}}}
  end

  test "delete room item", %{zone: zone} do
    room = create_room(zone, %{name: "Forest Path"})
    NamedProcess.start_link({Game.Room, room.id})

    item = create_item()
    room_item = create_room_item(room, item, %{spawn_interval: 15})

    {:ok, _room_item} = Room.delete_item(room_item.id)

    assert_receive {_, {:cast, {:update, _}}}
  end

  describe "exits" do
    test "create an exit", %{zone: zone} do
      room1 = create_room(zone, %{name: "Forest Path"})
      room2 = create_room(zone, %{name: "Forest Path", y: 2})

      NamedProcess.start_link({Game.Room, room1.id})
      NamedProcess.start_link({Game.Room, room2.id})

      {:ok, _room_exit} = Room.create_exit(%{"start_room_id" => room1.id, "finish_room_id" => room2.id, "direction" => "south"})

      room1_id = room1.id
      assert_receive {{Game.Room, ^room1_id}, {:cast, {:update, _}}}

      room2_id = room2.id
      assert_receive {{Game.Room, ^room2_id}, {:cast, {:update, _}}}
    end

    test "delete a room exit", %{zone: zone} do
      room1 = create_room(zone, %{name: "Forest Path"})
      room2 = create_room(zone, %{name: "Forest Path", y: 2})

      NamedProcess.start_link({Game.Room, room1.id})
      NamedProcess.start_link({Game.Room, room2.id})

      {:ok, room_exit} = Room.create_exit(%{"start_room_id" => room1.id, "finish_room_id" => room2.id, "direction" => "south"})
      {:ok, _room_exit} = Room.delete_exit(room_exit.id)

      room1_id = room1.id
      assert_receive {{Game.Room, ^room1_id}, {:cast, {:update, _}}}

      room2_id = room2.id
      assert_receive {{Game.Room, ^room2_id}, {:cast, {:update, _}}}
    end

    test "create an exit with proficiency requirements", %{zone: zone} do
      room1 = create_room(zone, %{name: "Forest Path"})
      room2 = create_room(zone, %{name: "Forest Path", y: 2})

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
      room = create_room(zone, %{})
      NamedProcess.start_link({Game.Room, room.id})

      {:ok, _feature} = Room.add_feature(room, %{"key" => "log", "short_description" => "short", "description" => "Long"})

      assert_receive {_, {:cast, {:update, _}}}
    end

    test "edit a room feature", %{zone: zone} do
      room = create_room(zone, %{})
      NamedProcess.start_link({Game.Room, room.id})

      {:ok, feature} = Room.add_feature(room, %{"key" => "log", "short_description" => "short", "description" => "Long"})
      {:ok, _room} = Room.edit_feature(room, feature.id, %{"key" => "log", "short_description" => "short", "description" => "longer"})

      assert_receive {_, {:cast, {:update, _}}}
      assert_receive {_, {:cast, {:update, _}}}
    end

    test "remove a room feature", %{zone: zone} do
      room = create_room(zone, %{})
      NamedProcess.start_link({Game.Room, room.id})

      {:ok, feature} = Room.add_feature(room, %{"key" => "log", "short_description" => "short", "description" => "Long"})
      {:ok, _feature} = Room.delete_feature(room, feature.id)

      assert_receive {_, {:cast, {:update, _}}}
      assert_receive {_, {:cast, {:update, _}}}
    end
  end

  describe "global features" do
    test "add a feature", %{zone: zone} do
      room = create_room(zone, %{})
      NamedProcess.start_link({Game.Room, room.id})

      {:ok, feature} = create_feature()

      {:ok, _feature} = Room.add_global_feature(room, Integer.to_string(feature.id))

      assert_receive {_, {:cast, {:update, _}}}
    end

    test "remove a feature", %{zone: zone} do
      room = create_room(zone, %{})
      NamedProcess.start_link({Game.Room, room.id})

      {:ok, feature} = create_feature()

      {:ok, _room} = Room.add_global_feature(room, Integer.to_string(feature.id))
      {:ok, _room} = Room.remove_global_feature(room, Integer.to_string(feature.id))

      assert_receive {_, {:cast, {:update, _}}}
      assert_receive {_, {:cast, {:update, _}}}
    end
  end

  describe "deleting a room" do
    setup %{zone: zone} do
      %{room: create_room(zone)}
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
