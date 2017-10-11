defmodule Web.Admin.ItemTagView do
  use Web, :view

  alias Data.Effect
  alias Data.Item
  alias Data.Stats
  alias Web.Admin.SharedView

  import Web.JSONHelper

  def types(), do: Item.types()
end
