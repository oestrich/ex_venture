defmodule Web.Admin.ItemView do
  use Web, :view
  use Game.Currency

  alias Web.Item
  alias Web.ItemAspect
  alias Data.Stats
  alias Web.Admin.SharedView

  import Web.KeywordsHelper
  import Web.JSONHelper
  import Ecto.Changeset

  def tags(changeset) do
    case get_field(changeset, :tags) do
      nil -> ""
      tags -> tags |> Enum.join(", ")
    end
  end

  def types(), do: Item.types()

  def item_aspects() do
    Enum.map(ItemAspect.all(), fn item_aspect ->
      {item_aspect.name, item_aspect.id}
    end)
  end
end
