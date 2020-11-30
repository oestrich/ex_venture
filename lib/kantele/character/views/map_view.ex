defmodule Kantele.Character.MapView do
  use Kalevala.Character.View

  def render("look", %{room: room, mini_map: mini_map}) do
    ~E"""
    {room-title id="<%= room.id %>" x="<%= to_string(room.x) %>" y="<%= to_string(room.y) %>" z="<%= to_string(room.z) %>"}<%= room.name %>{/room-title}
    <%= mini_map.display %>
    """
  end
end
