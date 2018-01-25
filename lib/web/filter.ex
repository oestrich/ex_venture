defmodule Web.Filter do
  @moduledoc """
  Filter an `Ecto.Query` by a map of parameters. Modules that use this should follow it's behaviour.
  """

  @doc """
  This will be reduced from the query params that are passed into `filter/3`
  """
  @callback filter_on_attribute(
              {attribute :: String.t(), value :: String.t()},
              query :: Ecto.Query.t()
            ) :: Ecto.Query.t()

  @doc """
  Common elements of filtering a query
  """
  @spec filter(query :: Ecto.Query.t(), filter :: map, module :: atom()) :: Ecto.Query.t()
  def filter(query, nil, _), do: query

  def filter(query, filter, module) do
    filter
    |> Enum.reject(&(elem(&1, 1) == ""))
    |> Enum.reduce(query, &module.filter_on_attribute/2)
  end
end
