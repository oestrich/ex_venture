defmodule Web.Admin.ZoneView do
  use Web, :view

  alias Game.Map
  alias Web.Admin.SharedView

  defdelegate map(zone), to: Map
end
