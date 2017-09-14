defmodule Game.Format.Shop do
  @moduledoc """
  Formatting for a shop
  """

  use Game.Currency

  def list(shop, items)
  def list(%{name: name}, items) do
    items = items
    |> Enum.map(&item/1)
    |> Enum.join("\n")

    "{magenta}#{name}{/magenta}\n#{items}"
  end

  defp item(item) do
    " - #{item.price} #{currency()} - #{quantity(item.quantity)} - {cyan}#{item.name}{/cyan}"
  end

  defp quantity(-1), do: "unlimited"
  defp quantity(amount), do: "#{amount} left"
end
