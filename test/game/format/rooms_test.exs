defmodule Game.Format.RoomsTest do
  use ExUnit.Case

  alias Game.Format.Rooms

  doctest Game.Format.Rooms

  describe "room formatting" do
    setup do
      room = %{
        id: 1,
        name: "Hallway",
        zone: %{name: "Cave"},
        description: "A hallway",
        currency: 100,
        players: [%{name: "Player"}],
        npcs: [%{name: "Bandit", extra: %{status_line: "[name] is here."}}],
        exits: [%{direction: "north"}, %{direction: "east"}],
        shops: [%{name: "Hole in the Wall"}],
        features: [%{key: "log", short_description: "A log"}],
      }

      items = [%{name: "Sword"}]

      %{room: room, items: items, map: "[ ]"}
    end

    test "includes the room name", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/Hallway/, Rooms.room(room, items, map))
    end

    test "includes the room description", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/A hallway/, Rooms.room(room, items, map))
    end

    test "includes the mini map", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/[ ]/, Rooms.room(room, items, map))
    end

    test "includes the room exits", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/north/, Rooms.room(room, items, map))
      assert Regex.match?(~r/east/, Rooms.room(room, items, map))
    end

    test "includes currency", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/100 gold/, Rooms.room(room, items, map))
    end

    test "includes the room items", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/Sword/, Rooms.room(room, items, map))
    end

    test "includes the players", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/Player/, Rooms.room(room, items, map))
    end

    test "includes the npcs", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/Bandit/, Rooms.room(room, items, map))
    end

    test "includes the shops", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/Hole in the Wall/, Rooms.room(room, items, map))
    end

    test "includes features", %{room: room, items: items, map: map} do
      assert Regex.match?(~r/log/, Rooms.room(room, items, map))
    end

    test "includes features if added to the description", %{room: room, items: items, map: map} do
      room = Map.put(room, :description, "[log]")

      refute Regex.match?(~r/\[log\]/, Rooms.room(room, items, map))
      assert Regex.match?(~r/log/, Rooms.room(room, items, map))
    end
  end
end
