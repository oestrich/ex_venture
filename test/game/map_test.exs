defmodule Game.MapTest do
  use Data.ModelCase
  doctest Game.Map

  alias Game.Door
  alias Game.Map

  setup do
    start_and_clear_doors()

    north = %{id: 1, x: 2, y: 1, map_layer: 1, exits: [%{id: 10, has_door: true, direction: "south", start_id: 1, finish_id: 5}]}
    east = %{id: 2, x: 3, y: 2, map_layer: 1, exits: [%{id: 11, has_door: true, direction: "west", start_id: 2, finish_id: 5}]}
    south = %{id: 3, x: 2, y: 3, map_layer: 1, exits: [%{direction: "north", start_id: 3, finish_id: 5}]}
    west = %{id: 4, x: 1, y: 2, map_layer: 1, exits: [%{direction: "east", start_id: 4, finish_id: 5}]}
    center = %{id: 5, x: 2, y: 2, map_layer: 1, exits: [
      %{id: 10, door_id: 10, has_door: true, direction: "north", start_id: 5, finish_id: 1},
      %{id: 11, door_id: 11, has_door: true, direction: "east", start_id: 5, finish_id: 2},
      %{direction: "south", start_id: 5, finish_id: 3},
      %{direction: "west", start_id: 5, finish_id: 4},
    ]}
    up = %{id: 6, x: 2, y: 2, map_layer: 2, exits: []}

    Door.load(10)
    Door.load(11)

    zone = %{rooms: [north, east, south, west, center, up]}
    %{zone: zone}
  end

  test "sizing a map up", %{zone: zone} do
    {{1, 1}, {3, 3}, map} = Map.size_of_map(zone, layer: 1)
    assert map |> length() == 5

    {{2, 2}, {2, 2}, map} = Map.size_of_map(zone, layer: 2)
    assert map |> length() == 1
  end

  describe "map grid" do
    test "filling out a grid for the map", %{zone: zone} do
      map =
        zone
        |> Map.map()
        |> Enum.map(fn (row) -> Enum.map(row, fn ({_, room}) -> room end) end)

      assert [
        [nil, nil, nil, nil, nil],
        [nil, nil, %{x: 2, y: 1}, nil, nil],
        [nil, %{x: 1, y: 2}, %{x: 2, y: 2}, %{x: 3, y: 2}, nil],
        [nil, nil, %{x: 2, y: 3}, nil, nil],
        [nil, nil, nil, nil, nil],
      ] = map
    end

    test "fetching another layer of the map", %{zone: zone} do
      map =
        zone
        |> Map.map(layer: 2, buffer: false)
        |> Enum.map(fn (row) -> Enum.map(row, fn ({_, room}) -> room end) end)

      assert [
        [%{x: 2, y: 2}],
      ] = map
    end
  end

  test "get layers in a map", %{zone: zone} do
    assert [1, 2] = Map.layers_in_map(zone)
  end

  describe "displaying the map" do
    test "display a map in text form", %{zone: zone} do
      map = [
        "                      ",
        "           [ ]        ",
        "            |         ",
        "     [ ] - [X] - [ ]  ",
        "            |         ",
        "           [ ]        ",
        "                      ",
      ]
      assert Map.display_map(zone, {2, 2, 1}) == Enum.join(map, "\n")
    end

    test "viewing another layer", %{zone: zone} do
      map = [
        "          ",
        "     [X]  ",
        "          ",
      ]
      assert Map.display_map(zone, {2, 2, 2}) == Enum.join(map, "\n")
    end

    test "view a mini map", %{zone: zone} do
      map = [
        "                      ",
        "           [ ]        ",
        "            |         ",
        "     [ ] - [X] - [ ]  ",
        "            |         ",
        "           [ ]        ",
        "                      ",
      ]
      assert Map.display_map(zone, {2, 2, 1}, [mini: true]) == Enum.join(map, "\n")
    end
  end

  describe "map colors" do
    test "blue rooms" do
      ["ocean", "river", "lake"]
      |> Enum.each(fn (ecology) ->
        assert Map.room_color(%{ecology: ecology}) == "map:blue"
      end)
    end

    test "brown rooms" do
      ["mountain", "road"]
      |> Enum.each(fn (ecology) ->
        assert Map.room_color(%{ecology: ecology}) == "map:brown"
      end)
    end

    test "green rooms" do
      ["hill", "field"]
      |> Enum.each(fn (ecology) ->
        assert Map.room_color(%{ecology: ecology}) == "map:green"
      end)
    end

    test "dark green rooms" do
      ["forest", "jungle"]
      |> Enum.each(fn (ecology) ->
        assert Map.room_color(%{ecology: ecology}) == "map:dark-green"
      end)
    end

    test "grey rooms" do
      ["town", "dungeon"]
      |> Enum.each(fn (ecology) ->
        assert Map.room_color(%{ecology: ecology}) == "map:grey"
      end)
    end

    test "light grey rooms" do
      ["inside"]
      |> Enum.each(fn (ecology) ->
        assert Map.room_color(%{ecology: ecology}) == "map:light-grey"
      end)
    end
  end
end
