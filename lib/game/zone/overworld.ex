defmodule Game.Zone.Overworld do
  @moduledoc """
  Overworld helpers
  """

  @sector_boundary 10

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

  def cell_sector(cell) do
    x = div(cell.x, @sector_boundary)
    y = div(cell.y, @sector_boundary)
    "#{x}-#{y}"
  end
end
