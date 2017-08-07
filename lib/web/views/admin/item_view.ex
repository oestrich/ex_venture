defmodule Web.Admin.ItemView do
  use Web, :view

  def keywords(%{changes: %{keywords: keywords}}) when keywords != nil do
    keywords(%{keywords: keywords})
  end
  def keywords(%{data: %{keywords: keywords}}) when keywords != nil do
    keywords(%{keywords: keywords})
  end
  def keywords(%{keywords: keywords}) when keywords != nil, do: keywords |> Enum.join(", ")
  def keywords(%{}), do: ""

  def stats(%{changes: %{stats: stats}}) when stats != nil do
    stats(%{stats: stats})
  end
  def stats(%{data: %{stats: stats}}) when stats != nil do
    stats(%{stats: stats})
  end
  def stats(%{stats: stats}) when stats != nil do
    case Poison.encode(stats) do
      {:ok, stats} -> stats
      _ -> ""
    end
  end
  def stats(%{}), do: ""

  def types(), do: Data.Item.types()
end
