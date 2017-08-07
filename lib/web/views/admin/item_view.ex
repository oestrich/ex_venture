defmodule Web.Admin.ItemView do
  use Web, :view

  def keywords(%{keywords: keywords}) when keywords != nil, do: keywords |> Enum.join(", ")
  def keywords(%{}), do: ""

  def stats(%{stats: stats}) when stats != nil do
    case Poison.encode(stats) do
      {:ok, stats} -> stats
      _ -> ""
    end
  end
  def stats(%{}), do: ""

  def types(), do: Data.Item.types()
end
