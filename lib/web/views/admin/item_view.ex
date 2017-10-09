defmodule Web.Admin.ItemView do
  use Web, :view
  use Game.Currency

  alias Data.Stats

  import Web.KeywordsHelper
  import Web.JSONHelper

  def types(), do: Data.Item.types()
end
