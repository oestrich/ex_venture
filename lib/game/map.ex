defmodule Game.Map do
  @moduledoc """
  Map out a zone
  """

  alias Data.Exit

  @doc """
  Find the coordinates for each room in a zone and the size of the zone

  1,1 is top left
  """
  @spec size_of_map(zone :: Zone.t) :: {{max_x :: integer, max_y :: integer}, [{{x :: integer, y :: integer}, Room.t}]}
  def size_of_map(zone)
  def size_of_map(%{rooms: []}), do: {{0, 0}, {0, 0}, []}
  def size_of_map(%{rooms: rooms}) do
    map = Enum.map(rooms, &({{&1.x, &1.y}, &1}))
    min_x = map |> Enum.min_by(fn ({{x, _y}, _room}) -> x end) |> elem(0) |> elem(0)
    min_y = map |> Enum.min_by(fn ({{_x, y}, _room}) -> y end) |> elem(0) |> elem(1)
    max_x = map |> Enum.max_by(fn ({{x, _y}, _room}) -> x end) |> elem(0) |> elem(0)
    max_y = map |> Enum.max_by(fn ({{_x, y}, _room}) -> y end) |> elem(0) |> elem(1)

    {{min_x, min_y}, {max_x, max_y}, map}
  end

  @doc """
  Generate a sorted list of lists for a zone map
  """
  @spec map(zone :: Zone.t) :: [[Room.t]]
  def map(zone, opts \\ []) do
    buffer = Keyword.get(opts, :buffer, true)

    {{min_x, min_y}, {max_x, max_y}, map} = size_of_map(zone)
    {{min_x, min_y}, {max_x, max_y}} =
      case buffer do
        true -> {{min_x - 1, min_y - 1}, {max_x + 1, max_y + 1}}
        false -> {{min_x, min_y}, {max_x, max_y}}
      end

    for y <- min_y..max_y do
      for x <- min_x..max_x do
        case Enum.find(map, fn ({coords, _room}) -> coords == {x, y} end) do
          {{^x, ^y}, room} -> {{x, y}, room}
          _ -> {{x, y}, nil}
        end
      end
    end
  end

  @doc """
  Generate a text view of the zone
  """
  @spec map(zone :: Zone.t) :: [[Room.t]]
  def display_map(zone, {x, y}) do
    zone
    |> map(buffer: false)
    |> Enum.map(fn (row) ->
      row |> Enum.map(&(display_room(&1, {x, y})))
    end)
    |> join_rooms()
    |> Enum.map(&("   #{&1}"))
    |> Enum.join("\n")
    |> String.replace(~r/-\+-/, "---")
  end

  @doc """
  Determine what the room looks like with it's walls
  """
  def display_room({_, nil}, _) do
    [
      "     ",
      "     ",
      "     ",
    ]
  end
  def display_room({_, room}, coords) do
    room_display =
      room
      |> _display_room(coords)
      |> color_room(room_color(room))

    [
      exits(room, :north),
      "#{exits(room, :west)}#{room_display}#{exits(room, :east)}",
      exits(room, :south),
    ]
  end

  defp _display_room(%{x: x, y: y}, {x, y}), do: "[X]"
  defp _display_room(%{}, _), do: "[ ]"

  defp color_room(room_string, nil), do: room_string
  defp color_room(room_string, color), do: "{#{color}}#{room_string}{/#{color}}"

  defp exits(room, direction) when direction in [:north, :south] do
    case Exit.exit_to(room, direction) do
      nil -> "+---+"
      _ -> "+   +"
    end
  end
  defp exits(room, direction) when direction in [:east, :west] do
    case Exit.exit_to(room, direction) do
      nil -> "|"
      _ -> " "
    end
  end

  @doc """
  Join map together

  The map is a list of rows of rooms, each room row is 3 lines
  """
  def join_rooms(rows) do
    rows
    |> Enum.map(fn (row) ->
      Enum.reduce(row, [], &join_row/2)
    end)
    |> Enum.reduce([], &join_rows/2)
  end

  @doc """
  Join an individual row of rooms together
  """
  def join_row(room, []), do: room
  def join_row(room, row) do
    row
    |> Enum.with_index()
    |> Enum.map(fn ({line, i}) ->
      [current_point | line] = line |> String.graphemes() |> Enum.reverse
      line = line |> Enum.reverse
      [room_point | room_line] = room |> Enum.at(i) |> String.graphemes()
      point = join_point(current_point, room_point)

      line ++ [point] ++ room_line
      |> Enum.join
    end)
  end

  @doc """
  Join each row of rooms together

  Each row of rooms are 3 lines long. The first line of the newly added row
  will be joined against the last row of the set.
  """
  def join_rows(row, []), do: row
  def join_rows(row, rows) do
    [line_1 | [line_2 | [line_3]]] = row
    [last_line | rows] = rows |> Enum.reverse
    rows = rows |> Enum.reverse
    last_line = join_line(last_line, line_1)
    rows ++ [last_line | [line_2 | [line_3]]]
  end

  @doc """
  Join a line together, zipping each point
  """
  def join_line(last_line, new_line) do
    new_line = new_line |> String.graphemes()

    last_line
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.map(fn ({point, i}) ->
      join_point(point, Enum.at(new_line, i))
    end)
  end

  @doc """
  Join a point in the map together

      iex> Game.Map.join_point(" ", " ")
      " "
      iex> Game.Map.join_point("|", "+")
      "+"

      iex> Game.Map.join_point(" ", "+")
      "+"
      iex> Game.Map.join_point("+", " ")
      "+"

      iex> Game.Map.join_point(" ", "-")
      "-"
      iex> Game.Map.join_point("-", " ")
      "-"

      iex> Game.Map.join_point("|", " ")
      "|"
      iex> Game.Map.join_point("|", " ")
      "|"
  """
  @spec join_point(String.t, String.t) :: String.t
  def join_point(" ", " "), do: " "
  def join_point(" ", point), do: point
  def join_point(point, " "), do: point
  def join_point(_, point), do: point

  @doc """
  Determine the color of the room in the map

      iex> Game.Map.room_color(%{ecology: "default"})
      nil
  """
  @spec room_color(room :: Room.t) :: String.t
  def room_color(room)
  def room_color(%{ecology: ecology}) do
    case ecology do
      ecology when ecology in ["ocean", "lake", "river"] -> "map:blue"
      ecology when ecology in ["mountain", "road"] -> "map:brown"
      ecology when ecology in ["hill", "field", "meadow"] -> "map:green"
      ecology when ecology in ["forest", "jungle"] -> "map:dark-green"
      ecology when ecology in ["town", "dungeon"] -> "map:grey"
      ecology when ecology in ["inside"] -> "map:light-grey"
      _ -> nil
    end
  end
  def room_color(_room), do: nil
end
