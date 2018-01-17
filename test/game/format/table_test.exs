defmodule Game.Format.TableTest do
  use ExUnit.Case
  doctest Game.Format.Table

  alias Game.Format.Table

  test "format a table" do
    row1 = ["Thing", "5/5", "Column 3"]
    row2 = ["Another Thing", "15/15", ""]
    column_sizes = [10, 5, 12]
    table = Table.format("Legend", [row1, row2], column_sizes)

    assert table == """
    +-----------------------------------+
    | Legend                            |
    +-----------------------------------+
    | Thing      | 5/5   | Column 3     |
    | Another Th | 15/15 |              |
    +-----------------------------------+
    """ |> String.trim
  end

  test "formatting a row with color in it" do
    row = Table.row(["10 gold", "unlimited", "{cyan}Sword{/cyan}"], [10, 10, 10])
    assert row == "| 10 gold    | unlimited  | {cyan}Sword{/cyan}      |"
  end

  describe "pad string" do
    test "less than total string length" do
      assert Table.pad_trailing("string", 5) == "string"
    end
  end
end
