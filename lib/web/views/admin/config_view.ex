defmodule Web.Admin.ConfigView do
  use Web, :view

  alias Game.Config

  def name("game_name"), do: "Game Name"
  def name("motd"), do: "Message of the Day"
end
