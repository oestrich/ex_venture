defmodule Web.SessionView do
  use Web, :view

  def grapevine_enabled?(), do: Gossip.configured?()
end
