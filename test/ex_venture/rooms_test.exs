defmodule ExVenture.RoomsTest do
  use ExVenture.DataCase

  alias ExVenture.Rooms

  describe "creating rooms" do
    test "successfully" do
      {:ok, zone} = TestHelpers.create_zone()

      {:ok, room} =
        Rooms.create(zone, %{
          name: "Room",
          description: "Description",
          listen: "Listen text",
          x: 0,
          y: 0,
          z: 0
        })

      assert room.name == "Room"
      assert room.description == "Description"
    end

    test "unsuccessful" do
      {:ok, zone} = TestHelpers.create_zone()

      {:error, changeset} =
        Rooms.create(zone, %{
          name: nil,
          description: "Description",
          listen: "Listen text",
          x: 0,
          y: 0,
          z: 0
        })

      assert changeset.errors[:name]
    end
  end

  describe "updating rooms - not live" do
    test "successfully" do
      {:ok, zone} = TestHelpers.create_zone()
      {:ok, room} = TestHelpers.create_room(zone, %{name: "Room"})

      {:ok, room} =
        Rooms.update(room, %{
          name: "New Room"
        })

      assert room.name == "New Room"
    end

    test "unsuccessful" do
      {:ok, zone} = TestHelpers.create_zone()
      {:ok, room} = TestHelpers.create_room(zone, %{name: "Room"})

      {:error, changeset} =
        Rooms.update(room, %{
          name: nil
        })

      assert changeset.errors[:name]
    end
  end

  describe "updating rooms - live" do
    test "successfully" do
      {:ok, zone} = TestHelpers.create_zone()
      {:ok, room} = TestHelpers.create_room(zone, %{name: "Room"})
      {:ok, room} = TestHelpers.publish_room(room)

      {:ok, room} =
        Rooms.update(room, %{
          name: "New Room"
        })

      assert room.name == "Room"
      assert Enum.count(room.staged_changes)
    end

    test "unsuccessful" do
      {:ok, zone} = TestHelpers.create_zone()
      {:ok, room} = TestHelpers.create_room(zone, %{name: "Room"})
      {:ok, room} = TestHelpers.publish_room(room)

      {:error, changeset} =
        Rooms.update(room, %{
          name: nil
        })

      assert changeset.errors[:name]
    end
  end
end
