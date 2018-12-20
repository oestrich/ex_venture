defmodule Web.SessionView do
  use Web, :view

  alias Game.Config

  def grapevine_enabled?(), do: Gossip.configured?()
end
