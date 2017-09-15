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
end
