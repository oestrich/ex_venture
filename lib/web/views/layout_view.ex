defmodule Web.LayoutView do
  use Web, :view

  import Web.Gettext, only: [gettext: 1]

  alias ExVenture.Users

  def admin?(user), do: Users.admin?(user)
end
