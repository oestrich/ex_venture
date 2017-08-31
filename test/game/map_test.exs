defmodule Game.MapTest do
  use Data.ModelCase

  alias Game.Map

  setup do
    north = %{x: 2, y: 1}
    east = %{x: 3, y: 2}
    south = %{x: 2, y: 3}
    west = %{x: 1, y: 2}
    center = %{x: 2, y: 2}

    zone = %{rooms: [north, east, south, west, center]}
    %{zone: zone}
  end

  test "sizing a map up", %{zone: zone} do
    {{3, 3}, map} = Map.size_of_map(zone)

    assert map |> length() == 5
  end

  test "filling out a grid for the map", %{zone: zone} do
    map = Map.map(zone)

    assert map == [
      [nil,           %{x: 2, y: 1}, nil],
      [%{x: 1, y: 2}, %{x: 2, y: 2}, %{x: 3, y: 2}],
      [nil,           %{x: 2, y: 3}, nil],
    ]
  end
end
