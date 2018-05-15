defmodule Web.ChatView do
  use Web, :view

  alias Web.Chat

  def active(0), do: "active"
  def active(_), do: ""
end
