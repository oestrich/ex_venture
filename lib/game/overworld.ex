defmodule Game.Overworld do
  @moduledoc """
  Overworld helpers
  """

  alias Data.Exit

  @type cell :: %{x: integer(), y: integer()}

  @sector_boundary 10
  @view_distance 10

  @doc """
  Break up an overworld id
  """
  @spec split_id(String.t()) :: {integer(), cell()}
  def split_id(overworld_id) do
    try do
      [zone_id, cell] = String.split(overworld_id, ":")
      [x, y] = String.split(cell, ",")
      cell = %{x: String.to_integer(x), y: String.to_integer(y)}

      {String.to_integer(zone_id), cell}
    rescue
      MatchError ->
        :error
    end
  end

  @doc """
  Take an overworld id and convert it to a zone id and sector
  """
  def sector_from_overworld_id(overworld_id) do
    {zone_id, cell} = split_id(overworld_id)
    {zone_id, cell_sector(cell)}
  end

  @doc """
  Figure out what sectors are in an overworld
  """
  @spec break_into_sectors([Sector.t()]) :: [Sector.id()]
  def break_into_sectors(overworld) do
    Enum.reduce(overworld, [], fn cell, sectors ->
      sector_id = cell_sector(cell)
      Enum.uniq([sector_id | sectors])
    end)
  end

  @doc """
  Determine a cell sector by a zone string id
  """
  def cell_sector(cell) do
    x = div(cell.x, @sector_boundary)
    y = div(cell.y, @sector_boundary)
    "#{x}-#{y}"
  end

  @doc """
  Determine exits for a cell in the overworld
  """
  def exits(zone, cell) do
    start_id = "overworld:#{zone.id}:#{cell.x},#{cell.y}"

    north = %{direction: "north", start_id: start_id, x: cell.x, y: cell.y - 1}
    south = %{direction: "south", start_id: start_id, x: cell.x, y: cell.y + 1}
    east = %{direction: "east", start_id: start_id, x: cell.x + 1, y: cell.y}
    west = %{direction: "west", start_id: start_id, x: cell.x - 1, y: cell.y}
    north_west = %{direction: "north west", start_id: start_id, x: cell.x - 1, y: cell.y - 1}
    north_east = %{direction: "north east", start_id: start_id, x: cell.x + 1, y: cell.y - 1}
    south_west = %{direction: "south west", start_id: start_id, x: cell.x - 1, y: cell.y + 1}
    south_east = %{direction: "south east", start_id: start_id, x: cell.x + 1, y: cell.y + 1}

    [north, south, east, west, north_west, north_east, south_west, south_east]
    |> Enum.filter(&in_overworld?(&1, zone))
    |> Enum.map(fn direction ->
      real_exit =
        Enum.find(zone.exits, &(&1.start_id == start_id && &1.direction == direction.direction))

      case real_exit do
        nil ->
          finish_id = "overworld:#{zone.id}:#{direction.x},#{direction.y}"

          %Exit{
            has_door: false,
            has_lock: false,
            requirements: [],
            id: direction.start_id,
            direction: direction.direction,
            start_id: direction.start_id,
            finish_id: finish_id
          }

        real_exit ->
          real_exit
      end
    end)
  end

  defp in_overworld?(direction, zone) do
    Enum.any?(zone.overworld_map, fn cell ->
      cell.x == direction.x && cell.y == direction.y && !cell_empty?(cell)
    end)
  end

  defp cell_empty?(cell) do
    is_nil(cell.c) && cell.s == " "
  end

  @doc """
  Generate an overworld map around the cell

  The cell's x,y will be in the center and an `X`
  """
  def map(zone, cell) do
    zone.overworld_map
    |> Enum.filter(fn overworld_cell ->
      close?(overworld_cell, cell, @view_distance)
    end)
    |> Enum.group_by(& &1.y)
    |> Enum.into([])
    |> Enum.sort(fn {y_a, _}, {y_b, _} ->
      y_a <= y_b
    end)
    |> Enum.reduce(%{}, fn {_y, cells}, map ->
      cells
      |> Enum.sort(&(&1.x <= &2.x))
      |> Enum.reduce(map, fn overworld_cell, map ->
        row = Map.get(map, overworld_cell.y, %{})
        row = Map.put(row, overworld_cell.x, format_cell(overworld_cell, cell))
        Map.put(map, overworld_cell.y, row)
      end)
    end)
    |> format_map(cell)
  end

  defp format_map(map, cell) do
    min_x = cell.x - @view_distance + 1
    max_x = cell.x + @view_distance - 1

    min_y = cell.y - @view_distance + 1
    max_y = cell.y + @view_distance - 1

    min_y..max_y
    |> Enum.map(fn y ->
      min_x..max_x
      |> Enum.map(fn x ->
        map
        |> Map.get(y, %{})
        |> Map.get(x, "  ")
      end)
      |> Enum.join()
    end)
    |> Enum.join("\n")
  end

  defp close?(cell_a, cell_b, expected) do
    actual =
      round(:math.sqrt(:math.pow(cell_b.x - cell_a.x, 2) + :math.pow(cell_b.y - cell_a.y, 2)))

    actual < expected
  end

  defp format_cell(overworld_cell, cell) do
    case overworld_cell.x == cell.x && overworld_cell.y == cell.y do
      true ->
        "X "

      false ->
        case overworld_cell.c do
          nil ->
            overworld_cell.s <> " "

          color ->
            "{#{color}}#{overworld_cell.s} {/#{color}}"
        end
    end
  end
end
