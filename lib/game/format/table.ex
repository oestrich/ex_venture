defmodule Game.Format.Table do
  @moduledoc """
  Format a table
  """

  alias Game.Color

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
      column = limit_visible(column, column_size)
      " #{pad_trailing(column, column_size)} "
    end)
    |> Enum.join("|")
    "|#{row}|"
  end

  @doc """
  Pad the end of a string with spaces

      iex> Game.Format.Table.pad_trailing("string", 7)
      "string "

      iex> Game.Format.Table.pad_trailing("string", 6)
      "string"

      iex> Game.Format.Table.pad_trailing("", 5, "-")
      "-----"
  """
  @spec pad_trailing(string :: String.t, width :: integer, pad_trailing :: String.t) :: String.t
  def pad_trailing(string, width, pad_string \\ " ") do
    no_color_string = Color.strip_color(string)
    no_color_string_length = String.length(no_color_string)
    case width - no_color_string_length do
      str_length when str_length > 0 ->
        padder = String.pad_trailing("", width - no_color_string_length, pad_string)
        "#{string}#{padder}"
      _ -> string
    end
  end

  @doc """
  Limit strings to visible characters

      iex> Game.Format.Table.limit_visible("string", 3)
      "str"

      iex> Game.Format.Table.limit_visible("{cyan}string{/cyan}", 3)
      "{cyan}str{/cyan}"
  """
  @spec limit_visible(string :: String.t, limit :: integer) :: String.t
  def limit_visible(string, limit) do
    string
    |> String.to_charlist
    |> _limit_visible(limit)
    |> to_string()
  end

  defp _limit_visible(characters, limit, pass \\ false)
  defp _limit_visible([], _limit, _), do: []
  defp _limit_visible([char | left], limit, _) when [char] == '{' do
    [char | _limit_visible(left, limit, true)]
  end
  defp _limit_visible([char | left], limit, _) when [char] == '}' do
    [char | _limit_visible(left, limit, false)]
  end
  defp _limit_visible([char | left], limit, true) do
    [char | _limit_visible(left, limit, true)]
  end
  defp _limit_visible([_char | left], limit, _) when limit <= 0 do
    _limit_visible(left, limit)
  end
  defp _limit_visible([char | left], limit, false) do
    [char | _limit_visible(left, limit - 1)]
  end
end
