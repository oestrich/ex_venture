defmodule Web.Admin.RoomController do
  use Web.AdminController

  alias Web.Room

  def show(conn, %{"id" => id}) do
    room = Room.get(id)
    npcs = Room.npcs(room.id)
    conn |> render("show.html", room: room, npcs: npcs)
  end
end
