defmodule Game.Format.Shop do
  @moduledoc """
  Formatting for a shop
  """

  use Game.Currency

  alias Game.Format.Table

  def list(shop, items)
  def list(%{name: name}, items) do
    rows = items
    |> Enum.map(&item/1)

    Table.format(name, rows, [10, 10, 30])
  end

  defp item(item) do
    ["#{item.price} #{currency()}", quantity(item.quantity), item.name]
  end

  defp quantity(-1), do: "unlimited"
  defp quantity(amount), do: "#{amount} left"
end
