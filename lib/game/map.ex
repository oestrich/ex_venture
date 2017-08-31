defmodule Game.Map do
  @moduledoc """
  Map out a zone
  """

  @doc """
  Find the coordinates for each room in a zone and the size of the zone

  1,1 is top left
  """
  @spec size_of_map(zone :: Zone.t) :: {{max_x :: integer, max_y :: integer}, [{{x :: integer, y :: integer}, Room.t}]}
  def size_of_map(zone)
  def size_of_map(%{rooms: rooms}) do
    map = Enum.map(rooms, &({{&1.x, &1.y}, &1}))
    max_x = map |> Enum.max_by(fn ({{x, _y}, _room}) -> x end) |> elem(0) |> elem(0)
    max_y = map |> Enum.max_by(fn ({{_x, y}, _room}) -> y end) |> elem(0) |> elem(1)

    {{max_x, max_y}, map}
  end

  @doc """
  Generate a sorted list of lists for a zone map
  """
  @spec map(zone :: Zone.t) :: [[Room.t]]
  def map(zone) do
    {{max_x, max_y}, map} = size_of_map(zone)

    for y <- 1..max_y do
      for x <- 1..max_x do
        case Enum.find(map, fn ({coords, _room}) -> coords == {x, y} end) do
          {{_x, _y}, room} -> room
          _ -> nil
        end
      end
    end
  end
end
