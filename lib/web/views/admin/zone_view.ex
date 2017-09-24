defmodule Web.Admin.ZoneView do
  use Web, :view

  alias Game.Map
  alias Web.Admin.SharedView

  defdelegate map(zone), to: Map

  def room_color(%{is_zone_exit: true}), do: "btn-warning"
  def room_color(_room), do: "btn-success"
end
