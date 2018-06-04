defmodule Game.Zone.OverworldTest do
  use Data.ModelCase

  alias Game.Zone.Overworld

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
