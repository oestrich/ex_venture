defmodule Game.Format.Table do
  @moduledoc """
  Format a table
  """

  import String, only: [pad_trailing: 2, pad_trailing: 3]

  @doc """
  Format an ASCII table
  """
  @spec format(legend :: String.t, rows :: [[String.t]], column_sizes ::  [integer]) :: String.t
  def format(legend, rows, column_sizes) do
    width = total_width(column_sizes)

    rows = rows
    |> Enum.map(&(row(&1, column_sizes)))
    |> Enum.join("\n")

    """
#{horizontal_line(width)}
| #{pad_trailing(legend, width - 4)} |
#{horizontal_line(width)}
#{rows}
#{horizontal_line(width)}
    """ |> String.trim
  end

  def horizontal_line(width) do
    "+#{pad_trailing("", width - 2, "-")}+"
  end

  @doc """
  Find the total width of the table from column sizes

  Counts the borders and padding spaces

      iex> Game.Format.Table.total_width([5, 10, 3])
      1+5+3+10+3+3+3
  """
  @spec total_width(column_sizes :: [integer]) :: integer
  def total_width(column_sizes) do
    Enum.reduce(column_sizes, 0, fn (column_size, size) -> column_size + size + 1 + 2 end) + 1
  end

  @spec row(row :: [String.t], column_sizes :: [integer]) :: String.t
  def row(row, column_sizes) do
    row = row
    |> Enum.with_index()
    |> Enum.map(fn ({column, index}) ->
      column_size = Enum.at(column_sizes, index)
      column = to_string(column)
      column = String.slice(column, 0, column_size)
      " #{pad_trailing(column, column_size)} "
    end)
    |> Enum.join("|")
    "|#{row}|"
  end
end
