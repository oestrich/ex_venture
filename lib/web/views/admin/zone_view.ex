defmodule Web.Admin.ZoneView do
  use Web, :view

  alias Game.Map

  defdelegate map(zone), to: Map
end
