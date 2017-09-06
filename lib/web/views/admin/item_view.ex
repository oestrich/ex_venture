defmodule Web.Admin.ItemView do
  use Web, :view

  alias Data.Stats

  import Web.EffectsHelper
  import Web.KeywordsHelper
  import Web.StatsHelper

  def types(), do: Data.Item.types()
end
