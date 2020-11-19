defmodule ExVenture.MiniMap.Connections do
  @moduledoc """
  Struct for tracking if a cell has a connection to another node
  """

  @derive Jason.Encoder
  defstruct [:north, :south, :east, :west, :up, :down]
end

defmodule ExVenture.MiniMap.Cell do
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
    connections: %ExVenture.MiniMap.Connections{}
  ]
end

defmodule ExVenture.MiniMap do
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
  defstruct [:id, :max_x, :max_y, :max_z, :min_x, :min_y, :min_z, cells: %{}]

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
end
