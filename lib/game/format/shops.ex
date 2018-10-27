defmodule Game.Format.Shops do
  @moduledoc """
  Formatting for a shop
  """

  use Game.Currency

  alias Game.Format
  alias Game.Format.Table

  @doc """
  Display the wares available for a shop
  """
  def list(shop, items)

  def list(shop, items) do
    rows =
      items
      |> Enum.map(&item/1)

    Table.format(Format.shop_name(shop), rows, [10, 10, 30])
  end

  defp item(item) do
    ["#{item.price} #{currency()}", quantity(item.quantity), Format.item_name(item)]
  end

  defp quantity(-1), do: "unlimited"
  defp quantity(amount), do: "#{amount} left"
end
