defmodule Web.Admin.RoomExitView do
  use Web, :view

  alias Web.Zone
  alias Game.Map

  defdelegate map(zone), to: Map

  def disabled_room_option(room) do
    [{"#{room.id} - #{room.name}", room.id}]
  end
end
