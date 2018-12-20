defmodule Game.Format.Shops do
  @moduledoc """
  Formatting for a shop
  """

  use Game.Currency

  import Game.Format.Context

  alias Game.Format
  alias Game.Format.Table

  @doc """
  Format a shop name, magenta

     iex> Shops.shop_name(%{name: "Shop"})
     "{shop}Shop{/shop}"
  """
  def shop_name(shop) do
    context()
    |> assign(:name, shop.name)
    |> Format.template("{shop}[name]{/shop}")
  end

  @doc """
  Display the wares available for a shop
  """
  def list(shop, items)

  def list(shop, items) do
    rows = Enum.map(items, &item/1)
    Table.format(Format.shop_name(shop), rows, [10, 10, 30])
  end

  defp item(item) do
    ["#{item.price} #{currency()}", quantity(item.quantity), Format.item_name(item)]
  end

  defp quantity(-1), do: "unlimited"
  defp quantity(amount), do: "#{amount} left"
end
