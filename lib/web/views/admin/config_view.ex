defmodule Web.Admin.ConfigView do
  use Web, :view

  alias Game.Config

  def name("game_name"), do: "Game Name"
  def name("motd"), do: "Message of the Day"
  def name("after_sign_in_message"), do: "After Sign In Message"
end
