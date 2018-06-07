defmodule Game.Zone.OverworldTest do
  use Data.ModelCase

  alias Game.Zone.Overworld

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
end
