defmodule Web.KeywordsHelper do
  @moduledoc """
  Helper for keywords in schemas
  """

  # Split keywords into an array of strings based on a comma
  def split_keywords(params = %{"keywords" => keywords}) do
    params |> Map.put("keywords", keywords |> String.split(",") |> Enum.map(&String.trim/1))
  end

  def split_keywords(params), do: params

  def keywords(%{changes: %{keywords: keywords}}) when keywords != nil do
    keywords(%{keywords: keywords})
  end

  def keywords(%{data: %{keywords: keywords}}) when keywords != nil do
    keywords(%{keywords: keywords})
  end

  def keywords(%{keywords: keywords}) when keywords != nil, do: keywords |> Enum.join(", ")
  def keywords(%{}), do: ""
end
