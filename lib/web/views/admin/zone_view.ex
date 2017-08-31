defmodule Web.Admin.ZoneView do
  use Web, :view

  alias Web.Zone

  @doc """
  Generate a sorted list of lists for a zone map
  """
  def map(zone) do
    {{max_x, max_y}, map} = Zone.map(zone)

    for y <- 1..max_y do
      for x <- 1..max_x do
        {x, y}
      end
    end
    |> Enum.map(fn (row) ->
      Enum.map(row, fn (coorindates) ->
        Enum.find(map, &(elem(&1, 0) == coorindates))
      end)
    end)
  end
end
