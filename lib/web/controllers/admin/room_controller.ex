defmodule Web.Admin.RoomController do
  use Web, :controller

  plug :put_layout, "admin.html"

  alias Web.Room

  def show(conn, %{"id" => id}) do
    room = Room.get(id)
    npcs = Room.npcs(room.id)
    conn |> render("show.html", room: room, npcs: npcs)
  end
end
