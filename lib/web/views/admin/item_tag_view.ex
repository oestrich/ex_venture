defmodule Web.Admin.ItemTagView do
  use Web, :view

  alias Data.Effect
  alias Data.Item
  alias Data.Stats

  import Web.JSONHelper

  def types(), do: Item.types()
end
