defmodule Web.StatsHelper do
  @moduledoc """
  Helper functions for displaying stats
  """

  def stats(%{changes: %{stats: stats}}) when stats != nil do
    stats(%{stats: stats})
  end
  def stats(%{data: %{stats: stats}}) when stats != nil do
    stats(%{stats: stats})
  end
  def stats(%{stats: stats}) when stats != nil do
    case Poison.encode(stats, pretty: true) do
      {:ok, stats} -> stats
      _ -> ""
    end
  end
  def stats(%{}), do: ""
end
