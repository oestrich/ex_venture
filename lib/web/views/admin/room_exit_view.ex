defmodule Web.Admin.RoomExitView do
  use Web, :view

  alias Game.Map
  alias Web.Admin.ZoneView
  alias Web.Zone

  defdelegate map(zone, opts), to: Map

  def layers(zone), do: Map.layers_in_map(zone)

  def layer_class(layer, layer), do: "active"
  def layer_class(_, _), do: ""

  def disabled_room_option(room) do
    [{"#{room.id} - #{room.name}", room.id}]
  end

  def proficiencies(proficiencies) do
    Enum.map(proficiencies, fn proficiency ->
      Elixir.Map.take(proficiency, [:id, :name])
    end)
  end

  def item_option(item) do
    {item.name, item.id}
  end
end
