defmodule Web.Admin.ZoneView do
  use Web, :view

  alias Game.Map
  alias Web.Admin.SharedView
  alias Web.Zone

  defdelegate map(zone, opts), to: Map

  def layers(zone), do: Map.layers_in_map(zone)

  def layer_class(zone, layer) do
    [first_layer | _] = layers(zone)
    case first_layer == layer do
      true -> "active"
      false -> ""
    end
  end

  def room_color(%{is_graveyard: true}), do: "btn-danger"
  def room_color(%{is_zone_exit: true}), do: "btn-warning"
  def room_color(_room), do: "btn-success"
end
