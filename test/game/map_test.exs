defmodule Game.MapTest do
  use Data.ModelCase
  doctest Game.Map

  alias Game.Map

  setup do
    north = %{id: 1, x: 2, y: 1, exits: [%{north_id: 1, south_id: 5}]}
    east = %{id: 2, x: 3, y: 2, exits: [%{east_id: 2, west_id: 5}]}
    south = %{id: 3, x: 2, y: 3, exits: [%{north_id: 5, south_id: 3}]}
    west = %{id: 4, x: 1, y: 2, exits: [%{east_id: 5, west_id: 4}]}
    center = %{id: 5, x: 2, y: 2, exits: [%{north_id: 1, south_id: 5}, %{east_id: 2, west_id: 5}, %{north_id: 5, south_id: 3}, %{east_id: 5, west_id: 4}]}

    zone = %{rooms: [north, east, south, west, center]}
    %{zone: zone}
  end

  test "sizing a map up", %{zone: zone} do
    {{1, 1}, {3, 3}, map} = Map.size_of_map(zone)

    assert map |> length() == 5
  end

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

  test "display a map in text form", %{zone: zone} do
    map = [
      "       +---+    ",
      "       |[ ]|    ",
      "   +---+   +---+",
      "   |[ ] [X] [ ]|",
      "   +---+   +---+",
      "       |[ ]|    ",
      "       +---+    ",
    ]
    assert Map.display_map(zone, {2, 2}) == Enum.join(map, "\n")
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
