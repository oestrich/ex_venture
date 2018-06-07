defmodule Game.Zone.Overworld do
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
end
