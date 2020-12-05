defmodule Kantele.MiniMap.Connections do
  @moduledoc """
  Struct for tracking if a cell has a connection to another node
  """

  @derive Jason.Encoder
  defstruct [:north, :south, :east, :west, :up, :down]
end

defmodule Kantele.MiniMap.Cell do
  @moduledoc """
  Cell of the MiniMap

  Tracks a room's position and what connections it has
  """

  @derive Jason.Encoder
  @derive {Inspect, only: [:x, :y, :z]}
  defstruct [
    :id,
    :map_color,
    :map_icon,
    :name,
    :x,
    :y,
    :z,
    connections: %Kantele.MiniMap.Connections{}
  ]
end

defmodule Kantele.MiniMap do
  @moduledoc """
  Structures and functions for dealing with minimaps of zones and rooms

  A MiniMap in the text stream looks like this:

       [ ]
        |
   [ ]-[ ]-[ ]-[ ]
                |
               [ ]-[ ]
  """

  @derive Jason.Encoder
  defstruct [:id, cells: %{}]

  @doc """
  Zoom the mini_map to visible rooms at the current location
  """
  def zoom(mini_map, {current_x, current_y, current_z}) do
    mini_map.cells
    |> Map.values()
    |> Enum.filter(fn cell ->
      cell.x >= current_x - 2 && cell.x <= current_x + 2 &&
        cell.y >= current_y - 2 && cell.y <= current_y + 2 &&
        cell.z >= current_z - 2 && cell.z <= current_z + 2
    end)
  end

  @doc """
  Turns a MiniMap struct into an ASCII map
  """
  def display(mini_map, {current_x, current_y, current_z}) do
    expanded_current_x = current_x * 4
    expanded_current_y = current_y * 2

    mini_map
    |> size_of_map()
    |> expand_character_map()
    |> fill_in(mini_map)
    |> Map.put({expanded_current_x, expanded_current_y, current_z}, "X")
    |> Enum.filter(fn {{_x, _y, z}, _character} -> z == current_z end)
    |> to_io()
  end

  defp to_io(expanded_map) do
    expanded_map
    |> Enum.map(fn {{x, y, _z}, character} -> {{x, y}, character} end)
    |> Enum.group_by(fn {{_x, y}, _character} -> y end)
    |> Enum.sort_by(fn {y, _row} -> -1 * y end)
    |> Enum.map(fn {_y, row} ->
      row
      |> Enum.sort_by(fn {{x, _y}, _character} -> x end)
      |> Enum.map(fn {_coordinate, character} -> character end)
    end)
    |> Enum.intersperse("\n")
  end

  @doc """
  Get the min and max x,y,z of a map
  """
  def size_of_map(mini_map) do
    cells = Map.values(mini_map.cells)

    {%{x: min_x}, %{x: max_x}} = Enum.min_max_by(cells, fn cell -> cell.x end)
    {%{y: min_y}, %{y: max_y}} = Enum.min_max_by(cells, fn cell -> cell.y end)
    {%{z: min_z}, %{z: max_z}} = Enum.min_max_by(cells, fn cell -> cell.z end)

    {{min_x, max_x}, {min_y, max_y}, {min_z, max_z}}
  end

  @doc """
  Expand the min/max x/y/z to a Map that contains coordinates for all possible spaces

  The resulting map is a set of coordinates pointing at empty strings to be filled in.
  """
  def expand_character_map({{min_x, max_x}, {min_y, max_y}, {min_z, max_z}}) do
    # x * 4 + 2
    expanded_min_x = min_x * 4 - 2
    expanded_max_x = max_x * 4 + 2

    expanded_min_y = min_y * 2 - 1
    expanded_max_y = max_y * 2 + 1

    # credo:disable-for-lines:7 Credo.Check.Refactor.Nesting
    Enum.reduce(min_z..max_z, %{}, fn z, map ->
      Enum.reduce(expanded_min_y..expanded_max_y, map, fn y, map ->
        Enum.reduce(expanded_min_x..expanded_max_x, map, fn x, map ->
          Map.put(map, {x, y, z}, " ")
        end)
      end)
    end)
  end

  @doc """
  Fill in the expanded map with characters representing the real room
  """
  def fill_in(expanded_map, mini_map) do
    Enum.reduce(mini_map.cells, expanded_map, fn {_coordinate, cell}, expanded_map ->
      x = cell.x * 4
      y = cell.y * 2
      z = cell.z

      map_color = cell.map_color || "white"

      expanded_map
      |> Map.put({x - 1, y, z}, ~s({color foreground="#{map_color}"}[))
      |> Map.put({x, y, z}, " ")
      |> Map.put({x + 1, y, z}, ~s(]{/color}))
      |> fill_in_direction(:north, {x, y, z}, cell.connections)
      |> fill_in_direction(:south, {x, y, z}, cell.connections)
      |> fill_in_direction(:east, {x, y, z}, cell.connections)
      |> fill_in_direction(:west, {x, y, z}, cell.connections)
    end)
  end

  def fill_in_direction(expanded_map, :north, {x, y, z}, %{north: north}) when north != nil do
    Map.put(expanded_map, {x, y + 1, z}, "|")
  end

  def fill_in_direction(expanded_map, :south, {x, y, z}, %{south: south}) when south != nil do
    Map.put(expanded_map, {x, y - 1, z}, "|")
  end

  def fill_in_direction(expanded_map, :east, {x, y, z}, %{east: east}) when east != nil do
    Map.put(expanded_map, {x + 2, y, z}, "-")
  end

  def fill_in_direction(expanded_map, :west, {x, y, z}, %{west: west}) when west != nil do
    Map.put(expanded_map, {x - 2, y, z}, "-")
  end

  def fill_in_direction(expanded_map, _direction, _coordinate, _connection), do: expanded_map
end
