defmodule Web.RaceView do
  use Web, :view

  alias Data.Stats

  def stat(%{starting_stats: stats}, field) do
    stats
    |> Stats.default()
    |> Map.get(field)
  end
end
