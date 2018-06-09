defmodule Game.Overworld do
  @moduledoc """
  Overworld helpers
  """

  @type cell :: %{x: integer(), y: integer()}

  @sector_boundary 10

  @doc """
  Break up an overworld id
  """
  @spec split_id(String.t()) :: {integer(), cell()}
  def split_id(overworld_id) do
    [zone_id, cell] = String.split(overworld_id, ":")
    [x, y] = String.split(cell, ",")
    cell = %{x: String.to_integer(x), y: String.to_integer(y)}

    {String.to_integer(zone_id), cell}
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
    start_id = Enum.join(["overworld", to_string(zone.id), "#{cell.x},#{cell.y}"], ":")

    north = %{direction: "north", start_id: start_id, x: cell.x, y: cell.y - 1}
    south = %{direction: "south", start_id: start_id, x: cell.x, y: cell.y + 1}
    east = %{direction: "east", start_id: start_id, x: cell.x + 1, y: cell.y}
    west = %{direction: "west", start_id: start_id, x: cell.x - 1, y: cell.y}

    [north, south, east, west]
    |> Enum.filter(fn direction ->
      Enum.any?(zone.overworld_map, fn cell ->
        cell.x == direction.x && cell.y == direction.y
      end)
    end)
    |> Enum.map(fn direction ->
      finish_id = Enum.join(["overworld", to_string(zone.id), "#{direction.x},#{direction.y}"], ":")
      %{direction: direction.direction, start_id: direction.start_id, finish_id: finish_id}
    end)
  end

  @doc """
  Generate an overworld map around the cell

  The cell's x,y will be in the center and an `X`
  """
  def map(zone, cell) do
    zone.overworld_map
    |> Enum.filter(fn overworld_cell ->
      close?(overworld_cell.x, cell.x, 10) && close?(overworld_cell.y, cell.y, 5)
    end)
    |> Enum.group_by(&(&1.y))
    |> Enum.into([])
    |> Enum.sort(fn {y_a, _}, {y_b, _} ->
      y_a <= y_b
    end)
    |> Enum.map(fn {_y, cells} ->
      cells
      |> Enum.sort(&(&1.x <= &2.x))
      |> Enum.map(&format_cell(&1, cell))
      |> Enum.join()
    end)
    |> Enum.join("\n")
  end

  defp close?(a, b, diff) do
    result = a - b
    result > (-1 * diff) && result < diff
  end

  defp format_cell(overworld_cell, cell) do
    case overworld_cell.x == cell.x && overworld_cell.y == cell.y do
      true ->
        "X"
      false ->
        "{#{overworld_cell.c}}#{overworld_cell.s}{/#{overworld_cell.c}}"
    end
  end
end
