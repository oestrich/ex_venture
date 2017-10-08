defmodule Web.Admin.ShopItemView do
  use Web, :view
  use Game.Currency

  def item_option(item) do
    {"#{item.name} - #{item.cost} #{currency()}", item.id}
  end
end
