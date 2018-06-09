defmodule Game.OverworldTest do
  use Data.ModelCase

  alias Data.Zone
  alias Game.Overworld

  describe "splitting up an overworld id" do
    test "pulls out zone id and x,y" do
      assert Overworld.split_id("3:1,2") == {3, %{x: 1, y: 2}}
    end
  end

  describe "overworld id to zone id and sector" do
    test "pulls out zone id and sector" do
      assert Overworld.sector_from_overworld_id("3:1,2") == {3, "0-0"}
    end
  end

  describe "calculating sectors" do
    setup do
      %{overworld: basic_overworld_map()}
    end

    test "sector every 10x10", %{overworld: overworld} do
      sectors = Overworld.break_into_sectors(overworld)

      assert length(sectors) == 50
    end

    test "a cell's sector" do
      assert Overworld.cell_sector(%{x: 3, y: 3}) == "0-0"
      assert Overworld.cell_sector(%{x: 97, y: 54}) == "9-5"
    end
  end

  describe "overworld exits" do
    setup do
      zone = %Zone{id: 1, overworld_map: basic_overworld_map()}
      %{zone: zone}
    end

    test "top left", %{zone: zone} do
      assert Overworld.exits(zone, %{x: 0, y: 0}) == [
        %{direction: "south", start_id: "overworld:1:0,0", finish_id: "overworld:1:0,1"},
        %{direction: "east", start_id: "overworld:1:0,0", finish_id: "overworld:1:1,0"},
      ]
    end

    test "top right", %{zone: zone} do
      assert Overworld.exits(zone, %{x: 99, y: 0}) == [
        %{direction: "south", start_id: "overworld:1:99,0", finish_id: "overworld:1:99,1"},
        %{direction: "west", start_id: "overworld:1:99,0", finish_id: "overworld:1:98,0"},
      ]
    end

    test "bottom left", %{zone: zone} do
      assert Overworld.exits(zone, %{x: 0, y: 49}) == [
        %{direction: "north", start_id: "overworld:1:0,49", finish_id: "overworld:1:0,48"},
        %{direction: "east", start_id: "overworld:1:0,49", finish_id: "overworld:1:1,49"},
      ]
    end

    test "bottom right", %{zone: zone} do
      assert Overworld.exits(zone, %{x: 99, y: 49}) == [
        %{direction: "north", start_id: "overworld:1:99,49", finish_id: "overworld:1:99,48"},
        %{direction: "west", start_id: "overworld:1:99,49", finish_id: "overworld:1:98,49"},
      ]
    end

    test "center", %{zone: zone} do
      assert Overworld.exits(zone, %{x: 1, y: 1}) == [
        %{direction: "north", start_id: "overworld:1:1,1", finish_id: "overworld:1:1,0"},
        %{direction: "south", start_id: "overworld:1:1,1", finish_id: "overworld:1:1,2"},
        %{direction: "east", start_id: "overworld:1:1,1", finish_id: "overworld:1:2,1"},
        %{direction: "west", start_id: "overworld:1:1,1", finish_id: "overworld:1:0,1"},
      ]
    end
  end
end
