defmodule Web.Admin.ClassView do
  use Web, :view

  def starting_stats(%{changes: %{starting_stats: starting_stats}}) when starting_stats != nil do
    starting_stats(%{starting_stats: starting_stats})
  end
  def starting_stats(%{data: %{starting_stats: starting_stats}}) when starting_stats != nil do
    starting_stats(%{starting_stats: starting_stats})
  end
  def starting_stats(%{starting_stats: starting_stats}) when starting_stats != nil do
    case Poison.encode(starting_stats, pretty: true) do
      {:ok, starting_stats} -> starting_stats
      _ -> ""
    end
  end
  def starting_stats(%{}), do: ""
end
