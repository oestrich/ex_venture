defmodule Web.Admin.ItemView do
  use Web, :view

  alias Data.Stats

  import Web.EffectsHelper
  import Web.StatsHelper

  def keywords(%{changes: %{keywords: keywords}}) when keywords != nil do
    keywords(%{keywords: keywords})
  end
  def keywords(%{data: %{keywords: keywords}}) when keywords != nil do
    keywords(%{keywords: keywords})
  end
  def keywords(%{keywords: keywords}) when keywords != nil, do: keywords |> Enum.join(", ")
  def keywords(%{}), do: ""

  def types(), do: Data.Item.types()
end
